using DataFrames
using CSV

function generate_field_csv(fields, instances)
    arr = fill("", 0, 7)
    for i in 0:instances-1
        for f in 0:fields-1
            row = fill("", 1, 7)
            row[1] = "TAG"
            row[3] = "field_$(f)_$(i)"
            row[5] = "DINT"
            row[7] = "(RADIX := Decimal, Constant := false, ExternalAccess := Read/Write)"
            arr = vcat(arr, row)
        end
    end
    for f in 0:fields-1
        row = fill("", 1, 7)
        row[1] = "TAG"
        row[3] = "field_$(f)"
        row[5] = "DINT[$(instances)]"
        row[7] = "(RADIX := Decimal, Constant := false, ExternalAccess := Read/Write)"
        arr = vcat(arr, row)
    end
    df = DataFrame(arr)
    CSV.write("out.csv", df, writeheader=false)
end