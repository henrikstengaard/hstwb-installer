import {formatBytes} from "../utils/Format";
import React from "react";
import RigidDiskBlockOverview from "./RigidDiskBlockOverview";
import TableContainer from "@mui/material/TableContainer";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import Paper from "@mui/material/Paper";
import TableRow from "@mui/material/TableRow";
import TableCell from "@mui/material/TableCell";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import Typography from "@mui/material/Typography";
import {set} from "lodash";
import {styled} from "@mui/material/styles";
import AccordionSummary from "@mui/material/AccordionSummary";
import DiskOverview from "./DiskOverview";

const StyledAccordionSummary = styled(AccordionSummary)(({theme}) => ({
    padding: 0,
    color: theme.palette.primary.main
}));

const initialState = {
    diskExpanded: true,
    rdbExpanded: true
}

export default function MediaOverview(props) {
    const {
        media
    } = props

    const [state, setState] = React.useState({...initialState});

    const handleChange = ({ name, value }) => {
        set(state, name, value)
        setState({...state})
    }
    
    const {
        diskExpanded,
        rdbExpanded
    } = state
    
    return (
        <TableContainer component={Paper}>
            <Table size="small" aria-label="media details">
                <TableBody>
                    <TableRow>
                        <TableCell>
                            <StyledAccordionSummary
                                expandIcon={<FontAwesomeIcon icon={diskExpanded ? 'chevron-up' : 'chevron-down'}/>}
                                onClick={() => handleChange({ name: 'diskExpanded', value: !diskExpanded})}
                            >
                                <Typography>
                                    {`Disk: ${media.model}, ${formatBytes(media.diskSize)}`}
                                </Typography>
                            </StyledAccordionSummary>
                        </TableCell>
                    </TableRow>
                    {diskExpanded && (
                        <TableRow>
                            <TableCell>
                                <DiskOverview media={media} />
                            </TableCell>
                        </TableRow>
                    )}
                    
                    {media.rigidDiskBlock && (
                        <React.Fragment>
                            <TableRow>
                                <TableCell>
                                    <StyledAccordionSummary
                                        expandIcon={<FontAwesomeIcon icon={rdbExpanded ? 'chevron-up' : 'chevron-down'}/>}
                                        onClick={() => handleChange({ name: 'rdbExpanded', value: !rdbExpanded})}
                                    >
                                        <Typography>
                                            {`Rigid disk block: ${media.rigidDiskBlock.diskProduct}, ${formatBytes(media.rigidDiskBlock.diskSize)}`}
                                        </Typography>
                                    </StyledAccordionSummary>
                                </TableCell>
                            </TableRow>
                            {rdbExpanded && (
                                <TableRow>
                                    <TableCell>
                                        <RigidDiskBlockOverview rigidDiskBlock={media.rigidDiskBlock} />
                                    </TableCell>
                                </TableRow>
                            )}
                        </React.Fragment>                        
                    )}
                </TableBody>
            </Table>
        </TableContainer>
    )
}