import { isNil } from 'lodash'
import React from 'react'
import FormControl from '@mui/material/FormControl'
import InputLabel from '@mui/material/InputLabel'
import OutlinedInput from '@mui/material/OutlinedInput'
import FormHelperText from '@mui/material/FormHelperText'
import {InputAdornment} from "@mui/material";

export default function TextField(props) {
    const {
        id,
        label,
        type = 'text',
        value = '',
        disabled,
        error = null,
        inputRef = null,
        endAdornment = null,
        onChange,
        onKeyDown
    } = props

    let outlinedInputProps = {}
    if (inputRef) {
        outlinedInputProps.inputRef = inputRef
    } else {
        outlinedInputProps.value = value
        outlinedInputProps.onChange = (event) => {
            if (isNil(onChange)) {
                return
            }
            onChange(event)
        }
        outlinedInputProps.onKeyDown = (event) => {
            if (isNil(onKeyDown)) {
                return
            }
            onKeyDown(event)
        }
    }
    
    if (endAdornment) {
        outlinedInputProps.endAdornment = (
            <InputAdornment position="end">
                {endAdornment}
            </InputAdornment>
        )
    }

    const hasError = !disabled && !isNil(error)
    
    return (
        <FormControl fullWidth variant="outlined" size="small">
            <InputLabel
                htmlFor={id}
                shrink={true}
                error={hasError}
            >
                {label}
            </InputLabel>
            <OutlinedInput
                id={id}
                notched
                label={label}
                type={type}
                disabled={disabled}
                error={hasError}
                margin="dense"
                fullWidth
                {...outlinedInputProps}
            />
            {hasError && (
                <FormHelperText error={true}>
                    {error}
                </FormHelperText>
            )}
        </FormControl>
    )
}