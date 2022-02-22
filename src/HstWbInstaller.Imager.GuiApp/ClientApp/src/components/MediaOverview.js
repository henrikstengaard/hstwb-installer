import {formatBytes} from "../utils/Format";
import {get} from "lodash";
import TableRow from "@mui/material/TableRow";
import TableCell from "@mui/material/TableCell";
import React from "react";
import TableContainer from "@mui/material/TableContainer";
import Paper from "@mui/material/Paper";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";

export default function MediaOverview(props) {
    const {
        media
    } = props
    
    return (
        <TableContainer component={Paper}>
            <Table size="small" aria-label="media overview">
                <TableBody>
                    <TableRow>
                        <TableCell
                            style={{textDecoration: 'underline', backgroundColor: 'rgb(184, 222, 245)'}}
                        >
                            Disk: {media.model}, {formatBytes(media.diskSize)}
                        </TableCell>
                    </TableRow>
                </TableBody>
            </Table>
        </TableContainer>
    )
}