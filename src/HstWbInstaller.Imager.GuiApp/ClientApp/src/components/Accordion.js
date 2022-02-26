import * as React from 'react';
import MuiAccordion from '@mui/material/Accordion';
import AccordionDetails from '@mui/material/AccordionDetails';
import AccordionSummary from '@mui/material/AccordionSummary';
import Typography from '@mui/material/Typography';
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export default function Accordion(props) {
    const {
        children,
        expanded: initialExpanded = false,
        id,
        title
    } = props

    const [expanded, setExpanded] = React.useState(initialExpanded);

    const handleChange = () => {
        setExpanded(!expanded)
    }
    
    return (
        <MuiAccordion expanded={expanded} onChange={() => handleChange()}>
            <AccordionSummary
                expandIcon={<FontAwesomeIcon icon="chevron-down"/>}
                aria-controls={`${id}-content`}
                id={`${id}-header`}
            >
                <Typography>
                    {title}
                </Typography>
            </AccordionSummary>
            <AccordionDetails>
                {children}
            </AccordionDetails>
        </MuiAccordion>
    );
}