import { isNil } from 'lodash'
import React from 'react'
import {Checkbox, FormControlLabel} from "@mui/material"

export default function CheckboxField(props) {
    const {
        id,
        name,
        label,
        value,
        disabled,
        onChange
    } = props

    const handleChange = (value) => {
        if (isNil(onChange)) {
            return
        }
        onChange(value)
    }

    return(
        <FormControlLabel
            control={<Checkbox
                checked={value}
                disabled={disabled}
                onChange={(event) => handleChange(event.target.checked)}
                id={id}
                name={name}
                color="primary" />
            }
            label={label}
            labelPlacement="end"
        />
    )
}