import {isNil} from "lodash";
import React from 'react'
import {Button as MuiButton} from "@mui/material";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export default function Button(props) {
    const {
        icon,
        children,
    } = props

    return (
        <MuiButton
            variant="contained"
            disableRipple
            startIcon={isNil(icon) ? null : <FontAwesomeIcon icon={icon}/>}
            {...props}
        >
            {children}
        </MuiButton>
    )
}