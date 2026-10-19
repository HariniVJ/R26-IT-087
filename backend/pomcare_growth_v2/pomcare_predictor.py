"""PomCare detector + crop classifier. Use with the accompanying config/models."""
from pathlib import Path
import io, json
import numpy as np
from PIL import Image, ImageOps
try:
    from .pomcare_utils import CLASSES, crop_region, tensor_image, decide, norm
except ImportError:
    from pomcare_utils import CLASSES, crop_region, tensor_image, decide, norm

class PomCarePredictor:
    def __init__(self,bundle_dir,device='cpu'):
        import tensorflow as tf
        from ultralytics import YOLO
        bundle=Path(bundle_dir)
        self.config=json.loads((bundle/'pipeline_config.json').read_text())
        assert self.config['class_names']==CLASSES, 'Wrong classifier class order'
        self.device=device
        self.detector=YOLO(str(bundle/'yolo_pomegranate_bud_recovery.pt'))
        expected={i:norm(c) for i,c in enumerate(CLASSES[:5])}
        actual={int(i):norm(n) for i,n in self.detector.names.items()}
        assert actual==expected, f'Unexpected detector labels: {actual}'
        self.classifier=tf.keras.models.load_model(bundle/'pomegranate_crop_classifier.h5',compile=False)
        assert self.classifier.output_shape[-1]==6, 'Classifier must have six outputs'
        assert tuple(self.classifier.input_shape[1:])==(224,224,3)
        assert self.classifier.get_layer('mobilenet_preprocess') is not None

    def predict(self,image):
        if isinstance(image,(bytes,bytearray)):
            image=Image.open(io.BytesIO(image))
        elif isinstance(image,(str,Path)):
            image=Image.open(image)
        if not isinstance(image,Image.Image):raise TypeError('Pass image bytes, a file path, or a PIL image')
        im=ImageOps.exif_transpose(image).convert('RGB')
        cfg=self.config
        rr=self.detector.predict(im,imgsz=cfg['imgsz'],conf=cfg['candidate_confidence_floor'],iou=cfg['nms_iou'],
                                 max_det=cfg['max_det'],device=self.device,verbose=False)[0]
        det_conf=None;det_class=None;box=None;probs=None
        if len(rr.boxes):
            k=int(rr.boxes.conf.argmax().item())
            det_conf=float(rr.boxes.conf[k].item());det_class=int(rr.boxes.cls[k].item())
            box=rr.boxes.xyxy[k].cpu().numpy().astype(float).tolist()
            cropped=crop_region(im,box,padding=cfg['crop_padding'])
            probs=self.classifier(tensor_image(cropped)[None],training=False).numpy()[0]
        c,reason,score=decide(det_conf,probs,cfg['detector_threshold'],cfg['classifier_threshold'])
        accepted=reason=='accepted'
        next_stage={'Bud':'Flower','Flower':'EarlyFruit','EarlyFruit':'MidGrowth','MidGrowth':'MatureFruit','MatureFruit':'Ready to Harvest'}
        messages={'accepted':'Pomegranate stage predicted.',
                  'no_detection':'No sufficiently confident pomegranate detection. Please take a closer, clearer photo.',
                  'unknown_class':'The detected region was classified as unrelated to the supported pomegranate stages.',
                  'uncertain_stage':'The stage is uncertain. Please take another clear photo of one bud, flower or fruit.'}
        return {'accepted':accepted,'reason':reason,'message':messages[reason],
                'stage':CLASSES[c] if accepted else None,
                'next_stage':next_stage[CLASSES[c]] if accepted else None,
                'classifier_score':score,'detector_score':det_conf,
                'detector_stage':CLASSES[det_class] if det_class is not None else None,
                'box':box,'class_scores':{name:float(p) for name,p in zip(CLASSES,probs)} if probs is not None else None,
                'validation_targets_met':cfg['validation_targets_met']}
