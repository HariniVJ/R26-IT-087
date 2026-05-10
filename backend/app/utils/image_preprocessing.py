import io
import numpy as np
from PIL import Image

IMAGE_SIZE = 224

def preprocess_image(image_bytes: bytes):
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = image.resize((IMAGE_SIZE, IMAGE_SIZE))

    img_array = np.array(image, dtype=np.float32)

    
    img_array = np.expand_dims(img_array, axis=0)
    return img_array