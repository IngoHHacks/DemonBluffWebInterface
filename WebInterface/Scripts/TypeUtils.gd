class_name TypeUtils

static func cast_to_type_of(of : Variant, variable : Variant) -> Variant:
    if of is int:
        return int(variable)
    elif of is float:
        return float(variable)
    elif of is bool:
        if variable is String:
            return variable.to_lower() == "true"
        return bool(variable)
    else:
        return variable
