import {isNil } from 'lodash'
import React from 'react'
import FormControl from '@mui/material/FormControl'
import Select from '@mui/material/Select'
import InputLabel from '@mui/material/InputLabel'
import MenuItem from '@mui/material/MenuItem'

export default function SelectField(props) {
    const {
        id,
        disabled,
        label,
        emptyLabel = '',
        value,
        options = [],
        onChange
    } = props

    const hasOptions = !isNil(options) && options.length > 0
    const labelId = `${id}-label`

    const handleChange = (newValue) => {
        if (isNil(onChange)) {
            return
        }
        onChange(newValue)
    }

    return (
        <FormControl fullWidth variant="outlined" size="small">
            <InputLabel
                id={labelId}
                shrink={true}>
                {label}
            </InputLabel>
            <Select
                labelId={labelId}
                id={id}
                notched
                value={hasOptions && !isNil(value) ? value : 'empty'}
                onChange={event => handleChange(event.target.value)}
                margin="dense"
                label={label}
                disabled={disabled}
            >
                {(hasOptions ? options : [{ title: emptyLabel, value: 'empty' }]).map((option, index) => {
                    return (<MenuItem dense key={index} value={option.value}>{option.title}</MenuItem>)
                })}
            </Select>
        </FormControl>
    )
}