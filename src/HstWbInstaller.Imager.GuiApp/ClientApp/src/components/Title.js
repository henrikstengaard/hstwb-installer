import React from "react";
import Typography from "@mui/material/Typography";

export default function Title(props) {
    const {
        description,
        text
    } = props
    
    return (
        <React.Fragment>
            <Typography variant="h2">
                {text}
            </Typography>
            <Typography>
                {description}
            </Typography>
        </React.Fragment>
    )
}