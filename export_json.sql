SELECT to_json(array_agg(r)) FROM 
    ( SELECT
        frame_time ft,
        trim(to_char(wavg,'9.999999')) wa,
        trim(to_char(min,'9.999999')) mn,
        trim(to_char(max,'9.999999')) mx,
        trim(to_char(volume, '999999999')) v
    FROM adaeur ) r ;