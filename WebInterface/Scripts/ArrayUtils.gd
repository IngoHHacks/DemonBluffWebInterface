'''
ArrayUtils.gd
This script provides utility functions for array manipulation.
All functions can handle both Godot Arrays and LuaTables.
'''

class_name ArrayUtils

# Returns a new array with unique elements from the input array.
static func unique(arr) -> Array:
    if arr is LuaTable:
        arr = arr.to_array()
    var seen = {}
    var result = []
    for item in arr:
        if not seen.has(item):
            seen[item] = true
            result.append(item)
    return result

# Returns the permutations of the input array with n picked elements.
static func permutations(arr, n: int) -> Array:
    if arr is LuaTable:
        arr = arr.to_array()
    if n <= 0 or n > arr.size():
        return []
    if n == 1:
        var arr2 = []
        for item in arr:
            arr2.append([item])
        return arr2
    var result = []
    for i in range(arr.size()):
        var current = arr[i]
        var remaining = arr.duplicate()
        remaining.remove_at(i)
        for perm in permutations(remaining, n - 1):
            result.append([current] + perm)
    return result

static func count(arr, callable) -> int:
    if arr is LuaTable:
        arr = arr.to_array()
    if callable is LuaFunction:
        callable = callable.to_callable()
    return arr.reduce(func(acc, item):
        return acc + (1 if callable.call(item) else 0)
    , 0)

static func filter(arr, callable) -> Array:
    if arr is LuaTable:
        arr = arr.to_array()
    if callable is LuaFunction:
        callable = callable.to_callable()
    return arr.filter(callable)

static func map(arr, callable) -> Array:
    if arr is LuaTable:
        arr = arr.to_array()
    if callable is LuaFunction:
        callable = callable.to_callable()
    return arr.map(callable)

static func reduce(arr, callable, initial) -> Variant:
    if arr is LuaTable:
        arr = arr.to_array()
    if callable is LuaFunction:
        callable = callable.to_callable()
    return arr.reduce(callable, initial)

static func first(arr, callable) -> Variant:
    if arr is LuaTable:
        arr = arr.to_array()
    if callable is LuaFunction:
        callable = callable.to_callable()
    for item in arr:
        if callable.call(item):
            return item
    return null

static func all(arr, callable) -> bool:
    if arr is LuaTable:
        arr = arr.to_array()
    if callable is LuaFunction:
        callable = callable.to_callable()
    return arr.all(callable)

static func any(arr, callable) -> bool:
    if arr is LuaTable:
        arr = arr.to_array()
    if callable is LuaFunction:
        callable = callable.to_callable()
    return arr.any(callable)

static func none(arr, callable) -> bool:
    if arr is LuaTable:
        arr = arr.to_array()
    if callable is LuaFunction:
        callable = callable.to_callable()
    return not arr.any(callable)

static func slice(arr, start: int, end: int) -> Array:
    if arr is LuaTable:
        arr = arr.to_array()
    return arr.slice(start, end)

static func find(arr, value) -> int:
    if arr is LuaTable:
        arr = arr.to_array()
    return arr.find(value)

# Alias for find
static func index_of(arr, value) -> int:
    return find(arr, value)
