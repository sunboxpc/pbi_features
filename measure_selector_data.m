let
    Source = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("nVNLCsJADL3K0G1deQQ9Ruld+gE3Sou4ERGKiuiy0laLtfUKLzcyLW6EZjp1lSHvveQlYRzHwgk5ClS0Qo0ST8UhVRSSz7kQGYWWO5Fo/KrJpwApKsZiWqCkSBBskOBs49rSKbDxagMK8hhmPS2NdAoXHAyZe+z0zFEWdNigq3/MGIzao5H7jN78V6BHdS4NLiGbMig8cgEJGuTkUYx8mKFr/0OT+3VfxHTZ/WSdC0khGppN5wo3ijh9Z4l02DWO2Cq8uWaDjLMNHgJVnr2z7X4A", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Type = _t]),
    #"Changed Type" = Table.TransformColumnTypes(Source,{{"Type", type text}}),
    #"Added Index" = Table.AddIndexColumn(#"Changed Type", "Index", 0, 1, Int64.Type)
in
    #"Added Index"