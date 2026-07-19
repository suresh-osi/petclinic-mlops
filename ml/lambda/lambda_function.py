import json

PET_TYPE_MAP = {"dog": 0, "cat": 1, "bird": 2, "hamster": 3, "snake": 4}


def lambda_handler(event, context):
    # Handle both GET (query params) and POST (body)
    if event.get("queryStringParameters"):
        body = event["queryStringParameters"]
    elif event.get("body"):
        body = json.loads(event["body"]) if isinstance(event["body"], str) else event["body"]
    else:
        body = event

    pet_age = int(body.get("pet_age", 5))
    pet_type = body.get("pet_type", "dog")
    visit_count = int(body.get("visit_count", 3))
    previous_no_show = int(body.get("previous_no_show", 0))

    # Rule-based model mimicking RandomForest trained output
    score = 0.0
    if pet_age > 8:
        score += 0.25
    if pet_age > 12:
        score += 0.15
    if previous_no_show == 1:
        score += 0.35
    if visit_count < 2:
        score += 0.15
    if visit_count == 0:
        score += 0.10
    if pet_type in ("cat", "bird"):
        score += 0.05

    probability_miss = min(max(score, 0.02), 0.95)
    probability_attend = round(1.0 - probability_miss, 4)
    probability_miss = round(probability_miss, 4)
    prediction = 1 if probability_miss > 0.5 else 0
    label = "likely_miss" if prediction == 1 else "likely_attend"

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
        "body": json.dumps({
            "prediction": prediction,
            "probability_miss": probability_miss,
            "probability_attend": probability_attend,
            "probability_miss_percent": f"{probability_miss*100:.1f}%",
            "label": label,
            "input": {"pet_age": pet_age, "pet_type": pet_type, "visit_count": visit_count, "previous_no_show": previous_no_show}
        })
    }
