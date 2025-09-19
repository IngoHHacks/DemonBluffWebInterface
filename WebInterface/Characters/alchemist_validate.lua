if this.num_maybe_cured == 0 then
    if this.num_cured == cured then
        return true
    end
    return false
else
    if this.num_cured + this.num_maybe_cured >= cured and this.num_cured <= cured then
        return UNKNOWN
    end
    return false
end
