DISEASE_TREATMENTS = {
    "Healthy": {
        "disease_name": "Healthy",
        "status": "Healthy fruit",
        "severity": "None",
        "description": "No visible disease symptoms detected.",
        "treatment": "No chemical treatment is needed.",
        "prevention": [
            "Continue regular field monitoring.",
            "Maintain proper irrigation.",
            "Remove fallen or damaged fruits from the field.",
            "Keep good farm hygiene."
        ]
    },

    "Alternaria": {
        "disease_name": "Alternaria",
        "status": "Disease detected",
        "severity": "Medium",
        "description": "Alternaria is a fungal disease that causes dark spots and reduces fruit quality.",
        "treatment": "Remove infected fruits and apply a suitable fungicide with agricultural officer advice.",
        "prevention": [
            "Avoid overhead watering.",
            "Improve air circulation around plants.",
            "Remove infected fruits quickly.",
            "Keep the field clean and dry."
        ]
    },

    "Anthracnose": {
        "disease_name": "Anthracnose",
        "status": "Disease detected",
        "severity": "High",
        "description": "Anthracnose is a fungal disease that can cause dark sunken lesions on fruits.",
        "treatment": "Remove infected fruits and use recommended fungicide treatment after expert advice.",
        "prevention": [
            "Remove diseased fruits and branches.",
            "Avoid keeping infected fruits near healthy fruits.",
            "Improve plant spacing.",
            "Avoid excess moisture on fruit surface."
        ]
    },

    "Bacterial_Blight": {
        "disease_name": "Bacterial_Blight",
        "status": "Disease detected",
        "severity": "High",
        "description": "Bacterial blight can spread through water splash and infected plant material.",
        "treatment": "Remove infected fruits and use copper-based treatment only with agricultural officer guidance.",
        "prevention": [
            "Avoid overhead irrigation.",
            "Disinfect pruning tools.",
            "Remove infected plant parts.",
            "Do not touch healthy fruits after handling infected fruits."
        ]
    },

    "Cercospora": {
        "disease_name": "Cercospora",
        "status": "Disease detected",
        "severity": "Medium",
        "description": "Cercospora is a fungal infection that affects fruit quality and plant health.",
        "treatment": "Remove infected parts and apply suitable fungicide if infection is severe.",
        "prevention": [
            "Keep field clean.",
            "Avoid dense planting.",
            "Remove infected leaves and fruits.",
            "Improve sunlight and air movement."
        ]
    }
}

def get_treatment_by_disease(disease_name: str):
    return DISEASE_TREATMENTS.get(disease_name)

def get_all_diseases():
    return list(DISEASE_TREATMENTS.values())