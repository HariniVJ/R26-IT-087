"""Pure data/metric helpers used by the Colab guide and checked locally."""
from pathlib import Path
import json, hashlib, zipfile, math
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageOps
CLASSES = ['Bud','Flower','EarlyFruit','MidGrowth','MatureFruit','Unknown']
ALIASES = {'bud':0,'budding':0,'flower':1,'flowering':1,'earlyfruit':2,'earlygrowth':2,'early':2,
           'midgrowth':3,'mid':3,'maturefruit':4,'mature':4,'ripe':4,'ripefruit':4}
EXTS = {'.jpg','.jpeg','.png','.bmp','.webp'}
def norm(s): return ''.join(c for c in s.lower() if c.isalnum())
def safe_extract(archive, destination):
    destination=Path(destination); destination.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(archive) as z:
        for info in z.infolist():
            dest=(destination/info.filename).resolve()
            if not dest.is_relative_to(destination.resolve()): raise ValueError('Unsafe ZIP path')
            if ((info.external_attr>>16)&0o170000)==0o120000: raise ValueError('ZIP symlink not supported')
        z.extractall(destination)
def image_hash(path):
    with Image.open(path) as im:
        im=im.convert('RGB'); im.load()
        return hashlib.sha256(str(im.size).encode()+im.tobytes()).hexdigest()
def parse_xml(xmlpath, imagepath):
    with Image.open(imagepath) as im: w,h=im.size
    root=ET.parse(xmlpath).getroot(); boxes=[]
    for obj in root.findall('object'):
        tag=obj.find('name')
        if tag is None: tag=obj.find('n')
        if tag is None or not tag.text: raise ValueError(f'Missing class: {xmlpath}')
        key=norm(tag.text)
        if key not in ALIASES: raise ValueError(f'Unknown XML label {tag.text!r}: {xmlpath}')
        bb=obj.find('bndbox')
        if bb is None: raise ValueError(f'Missing bounding box: {xmlpath}')
        x1,y1,x2,y2=[float(bb.findtext(k)) for k in ['xmin','ymin','xmax','ymax']]
        # Pascal VOC uses 1-based inclusive coordinates; convert to 0-based exclusive bounds.
        x1=max(0,x1-1);y1=max(0,y1-1);x2=min(w,x2);y2=min(h,y2)
        if not (x2>x1 and y2>y1): raise ValueError(f'Invalid box: {xmlpath}')
        boxes.append([ALIASES[key],x1,y1,x2,y2])
    if not boxes: raise ValueError(f'Positive image has no boxes: {xmlpath}')
    return boxes,w,h

def parse_yolo(labelpath, imagepath):
    with Image.open(imagepath) as im: w,h=im.size
    boxes=[]
    for line in Path(labelpath).read_text().splitlines():
        if not line.strip(): continue
        vals=[float(x) for x in line.split()]
        if len(vals)!=5: raise ValueError(f'Expected 5 detection label values: {labelpath}')
        c,xc,yc,bw,bh=vals
        if not all(np.isfinite(vals)) or int(c)!=c or not 0<=c<5 or not (0<=xc<=1 and 0<=yc<=1 and 0<bw<=1 and 0<bh<=1):
            raise ValueError(f'Invalid YOLO values: {labelpath}')
        x1=max(0,(xc-bw/2)*w);y1=max(0,(yc-bh/2)*h)
        x2=min(w,(xc+bw/2)*w);y2=min(h,(yc+bh/2)*h)
        if x2<=x1 or y2<=y1: raise ValueError(f'Invalid YOLO box: {labelpath}')
        boxes.append([int(c),x1,y1,x2,y2])
    if not boxes: raise ValueError(f'Unannotated positive image: {labelpath}')
    return boxes,w,h

def yolo_text(boxes,w,h):
    return ''.join(f'{int(c)} {(x1+x2)/(2*w):.8f} {(y1+y2)/(2*h):.8f} {(x2-x1)/w:.8f} {(y2-y1)/h:.8f}\n' for c,x1,y1,x2,y2 in boxes)

def crop_region(im, xyxy, padding=0.12):
    w,h=im.size; x1,y1,x2,y2=map(float,xyxy)
    dx=(x2-x1)*padding;dy=(y2-y1)*padding
    box=(max(0,math.floor(x1-dx)),max(0,math.floor(y1-dy)),min(w,math.ceil(x2+dx)),min(h,math.ceil(y2+dy)))
    if box[2]<=box[0] or box[3]<=box[1]: raise ValueError('Empty crop')
    return im.crop(box)
def tensor_image(im):
    return np.asarray(im.convert('RGB').resize((224,224),Image.Resampling.BILINEAR),dtype=np.float32)/255.0

def iou_one(box, targets):
    a=np.asarray(box,float); b=np.asarray(targets,float).reshape(-1,4)
    if len(b)==0:return np.zeros(0)
    inter=np.maximum(0,np.minimum(a[2:],b[:,2:])-np.maximum(a[:2],b[:,:2])).prod(axis=1)
    area=np.maximum(0,a[2:]-a[:2]).prod();areas=np.maximum(0,b[:,2:]-b[:,:2]).prod(axis=1)
    return inter/np.maximum(area+areas-inter,1e-9)

def audit_and_filter(records):
    # records must already have hash, kind, split, path, boxes, width, height.
    groups={}
    for r in records: groups.setdefault(r['hash'],[]).append(r)
    kept=[];removed=[];errors=[]
    priority={'test':0,'val':1,'train':2}
    for digest, group in groups.items():
        kinds={r['kind'] for r in group}
        labels={tuple(sorted({int(b[0]) for b in r['boxes']})) for r in group}
        if len(kinds)>1 or len(labels)>1:
            errors.append({'reason':'Identical pixels with incompatible labels','paths':[r['path'] for r in group]});continue
        splits={r['split'] for r in group}
        if 'test' in splits and 'val' in splits:
            errors.append({'reason':'Validation/test overlap needs review','paths':[r['path'] for r in group]});continue
        group=sorted(group,key=lambda r:(priority[r['split']],r['path']))
        kept.append(group[0])
        for r in group[1:]:removed.append({'removed':r['path'],'split':r['split'],'kept':group[0]['path'],'reason':'Exact pixel duplicate; retain held-out image first'})
    return kept,removed,errors

def annotations_agree(a, b, min_iou=0.90):
    """Same pixels require equivalent object counts/classes and near-identical boxes."""
    if a['kind'] != b['kind'] or (a['width'],a['height']) != (b['width'],b['height']):
        return False
    aa,bb=a['boxes'],b['boxes']
    if len(aa)!=len(bb): return False
    remaining=set(range(len(bb)))
    # Tightest boxes first keeps nested boxes from taking each other's matches.
    for box in sorted(aa,key=lambda x:(x[3]-x[1])*(x[4]-x[2])):
        candidates=[i for i in sorted(remaining) if int(bb[i][0])==int(box[0])]
        if not candidates:return False
        overlaps=iou_one(box[1:],[bb[i][1:] for i in candidates])
        j=int(overlaps.argmax())
        if overlaps[j]<min_iou:return False
        remaining.remove(candidates[j])
    return True

def deduplicate_pool(records):
    """Merge exact copies and linked capture groups before creating any split."""
    records=sorted(records,key=lambda r:r['source_key'])
    parents=list(range(len(records)))
    def root(i):
        while parents[i]!=i:
            parents[i]=parents[parents[i]];i=parents[i]
        return i
    def union(i,j):
        a,b=root(i),root(j)
        if a!=b:parents[max(a,b)]=min(a,b)
    seen_hash={};seen_group={};duplicates={}
    for i,r in enumerate(records):
        for mapping,key in [(seen_hash,r['hash']),(seen_group,r['group'])]:
            if key in mapping:union(i,mapping[key])
            else:mapping[key]=i
        duplicates.setdefault(r['hash'],[]).append(i)
    components={}
    for i,r in enumerate(records):components.setdefault(root(i),set()).add(r['group'])
    group_ids={k:'group_'+hashlib.sha256(json.dumps(sorted(v)).encode()).hexdigest()[:24]
               for k,v in components.items()}
    kept=[];removed=[];errors=[]
    for digest,indices in sorted(duplicates.items()):
        first=records[indices[0]]
        if any(not annotations_agree(first,records[i]) for i in indices[1:]):
            errors.append({'reason':'Identical pixels with conflicting classes, kinds or boxes',
                           'sha256':digest,'source_keys':[records[i]['source_key'] for i in indices],
                           'annotations':[records[i]['boxes'] for i in indices]})
            continue
        retained=dict(first)
        retained['group']=group_ids[root(indices[0])]
        retained['provenance']=[{'source_key':records[i]['source_key'],
                                'original_split':records[i].get('original_split'),
                                'original_group':records[i]['group']} for i in indices]
        retained.pop('split',None)
        kept.append(retained)
        for i in indices[1:]:
            removed.append({'removed':records[i]['source_key'],'kept':first['source_key'],
                            'reason':'Same decoded pixels; deduplicated before splitting'})
    return sorted(kept,key=lambda r:r['source_key']),removed,errors

def split_80_20(records, seed=42, outer_folds=5, inner_folds=10):
    """Fixed fold 0 twice: ~80/20 development/test, then ~90/10 fitting/validation."""
    from sklearn.model_selection import StratifiedGroupKFold
    import sklearn
    if outer_folds!=5 or inner_folds!=10:
        raise ValueError('This guide implements 5 outer / 10 inner folds (72/8/20).')
    rr=[dict(r) for r in sorted(records,key=lambda r:r['source_key'])]
    if len({r['hash'] for r in rr})!=len(rr):
        raise ValueError('Deduplicate exact images before splitting')
    # Source-aware Unknown strata help retain both studio and real-scene negatives.
    def stratum(r):
        if r['kind']=='negative':return 'Unknown:'+r['source']
        counts=np.bincount([int(b[0]) for b in r['boxes']],minlength=5)
        if not counts.sum():raise ValueError('Positive image is missing boxes')
        return CLASSES[int(counts.argmax())]
    y=np.array([stratum(r) for r in rr]);g=np.array([r['group'] for r in rr])
    if len(set(g))<outer_folds:raise ValueError('Need at least five independent groups for the outer split')
    outer=StratifiedGroupKFold(n_splits=outer_folds,shuffle=True,random_state=seed)
    dev,test=next(outer.split(np.zeros(len(rr)),y,g))
    if len(set(g[dev]))<inner_folds:
        raise ValueError('Need at least ten independent development groups for internal validation')
    inner=StratifiedGroupKFold(n_splits=inner_folds,shuffle=True,random_state=seed+1)
    fit_rel,val_rel=next(inner.split(np.zeros(len(dev)),y[dev],g[dev]))
    positions={'train':dev[fit_rel],'val':dev[val_rel],'test':test}
    for split,indices in positions.items():
        for i in indices:rr[i]['split']=split
    for i,left in enumerate(positions):
        for right in list(positions)[i+1:]:
            if set(g[positions[left]]) & set(g[positions[right]]):
                raise AssertionError('A capture group crosses the split')
    for split in positions:
        chosen=[r for r in rr if r['split']==split]
        homogeneous={int(r['boxes'][0][0]) for r in chosen if r['kind']=='positive'
                     and len({int(b[0]) for b in r['boxes']})==1}
        missing=set(range(5))-homogeneous
        if missing or not any(r['kind']=='negative' for r in chosen):
            raise ValueError(f'{split}: missing homogeneous stages {sorted(missing)} or negative examples. '
                             'Add independent labelled groups; do not hunt test splits.')
    counts={s:len(p) for s,p in positions.items()}
    protocol={'scheme':'80% development / 20% test; 10% of development for validation',
              'seed':seed,'outer_folds':outer_folds,'inner_folds':inner_folds,
              'selected_outer_fold':0,'selected_inner_fold':0,
              'method':'StratifiedGroupKFold, majority positive stage and negative source strata',
              'sklearn_version':sklearn.__version__,'unique_images':len(rr),
              'counts':counts,'fractions':{s:n/len(rr) for s,n in counts.items()},
              'groups':{s:len(set(g[p])) for s,p in positions.items()},
              'test_used_for_selection':False}
    return rr,protocol

def decide(det_conf, probs, detector_threshold, classifier_threshold):
    if det_conf is None or det_conf<detector_threshold or probs is None:
        return 5,'no_detection',None
    p=np.asarray(probs); c=int(p.argmax()); score=float(p[c])
    if c==5:return 5,'unknown_class',score
    if score<classifier_threshold:return 5,'uncertain_stage',score
    return c,'accepted',score

def classification_metrics(truth,pred):
    truth=np.asarray(truth,int);pred=np.asarray(pred,int)
    if len(truth)!=len(pred) or not len(truth):raise ValueError('Empty or mismatched labels')
    cm=np.zeros((6,6),int)
    np.add.at(cm,(truth,pred),1)
    tp=cm.diagonal();support=cm.sum(1);pc=cm.sum(0)
    precision=np.divide(tp,pc,out=np.zeros(6,float),where=pc>0)
    recall=np.divide(tp,support,out=np.zeros(6,float),where=support>0)
    f1=np.divide(2*precision*recall,precision+recall,out=np.zeros(6,float),where=precision+recall>0)
    positive=truth!=5;negative=truth==5
    return {'accuracy':float(np.mean(truth==pred)),
        'stage_accuracy':float(np.mean(truth[positive]==pred[positive])) if positive.any() else None,
        'negative_rejection':float(np.mean(pred[negative]==5)) if negative.any() else None,
        'false_rejection':float(np.mean(pred[positive]==5)) if positive.any() else None,
        'stage_macro_f1':float(f1[:5].mean()),'macro_f1':float(f1.mean()),
        'precision':precision.tolist(),'recall':recall.tolist(),'f1':f1.tolist(),'support':support.tolist(),'confusion':cm.tolist()}

def measure_cache(cache,dt,ct):
    included=[r for r in cache if r['truth'] is not None]
    pred=[decide(r['det_conf'],r['probs'],dt,ct)[0] for r in included]
    return classification_metrics([r['truth'] for r in included],pred)
