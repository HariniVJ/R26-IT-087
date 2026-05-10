def get_tree_stage(age: float) -> int:
    age = float(age)

    if age <= 1:
        return 1
    elif age <= 2:
        return 2
    elif age <= 3:
        return 3
    else:
        return 4


def get_stage_name(stage: int) -> str:
    stage_names = {
        1: "first_year",
        2: "second_year",
        3: "third_year",
        4: "fourth_year_onwards"
    }
    return stage_names.get(stage, "unknown")


def classify_fertilizer_requirement(nitrogen: float, phosphorus: float, potassium: float) -> tuple[str, float]:
    """
    Simple fertilizer class logic.
    You can later replace this with ML model prediction.
    """

    optimal_n = 70
    optimal_p = 50
    optimal_k = 225

    n_deficiency = max(0, optimal_n - nitrogen)
    p_deficiency = max(0, optimal_p - phosphorus)
    k_deficiency = max(0, optimal_k - potassium)

    deficiency_score = (
        0.50 * n_deficiency +
        0.25 * p_deficiency +
        0.25 * k_deficiency
    )

    if deficiency_score > 40:
        fertilizer_class = "HIGH"
    elif deficiency_score >= 20:
        fertilizer_class = "MEDIUM"
    else:
        fertilizer_class = "LOW"

    return fertilizer_class, deficiency_score


def get_fertilizer_amount(stage: int, fertilizer_class: str) -> dict:
    """
    Amounts are grams per tree per application.
    Adjust according to your official pomegranate fertilizer table.
    """

    base_table = {
        1: {"urea": 40, "tsp": 45, "mop": 40},
        2: {"urea": 60, "tsp": 70, "mop": 55},
        3: {"urea": 150, "tsp": 185, "mop": 125},
        4: {"urea": 200, "tsp": 275, "mop": 175},
    }

    multiplier = {
        "LOW": 0.75,
        "MEDIUM": 1.00,
        "HIGH": 1.25,
    }

    base = base_table[stage]
    factor = multiplier.get(fertilizer_class.upper(), 1.0)

    return {
        "urea_g": round(base["urea"] * factor, 2),
        "tsp_g": round(base["tsp"] * factor, 2),
        "mop_g": round(base["mop"] * factor, 2),
    }


def get_ec_warning(ec: float) -> str:
    if ec > 2000:
        return "High EC detected. Soil salinity may be high. Avoid excessive fertilizer."
    elif ec < 300:
        return "Low EC detected. Nutrient concentration may be low."
    else:
        return "EC level is acceptable."


def predict_fertilizer_from_mobile(
    moisture: float,
    temp: float,
    ec: float,
    ph: float,
    nitrogen: float,
    phosphorus: float,
    potassium: float,
    tree_age: float
) -> dict:
    stage = get_tree_stage(tree_age)
    fertilizer_class, deficiency_score = classify_fertilizer_requirement(
        nitrogen=nitrogen,
        phosphorus=phosphorus,
        potassium=potassium
    )

    fertilizer_amount = get_fertilizer_amount(stage, fertilizer_class)
    ec_warning = get_ec_warning(ec)

    return {
        "fertilizer_class": fertilizer_class,
        "deficiency_score": round(deficiency_score, 2),
        "tree_age": tree_age,
        "stage": stage,
        "stage_name": get_stage_name(stage),
        "fertilizer_amount": fertilizer_amount,
        "ec_warning": ec_warning,
        "input_used": {
            "moisture": moisture,
            "temp": temp,
            "ec": ec,
            "ph": ph,
            "nitrogen": nitrogen,
            "phosphorus": phosphorus,
            "potassium": potassium,
            "tree_age": tree_age,
            "stage": stage
        }
    }