import React from "react";
import TableContainer from "@mui/material/TableContainer";
import Paper from "@mui/material/Paper";
import Table from "@mui/material/Table";
import {TableHead} from "@mui/material";
import TableRow from "@mui/material/TableRow";
import TableCell from "@mui/material/TableCell";
import TableBody from "@mui/material/TableBody";
import Stack from "@mui/material/Stack";
import {formatBytes} from "../utils/Format";

export default function DiskOverview(props) {
    const {
        media
    } = props

    const parts = []
    
    if (media.rigidDiskBlock) {
        parts.push({
            name: media.rigidDiskBlock.diskProduct,
            type: 'amiga',
            size: media.rigidDiskBlock.diskSize,
            percentSize: Math.round((100 / media.diskSize) * media.rigidDiskBlock.diskSize)
        })
    }

    const partSize = media.rigidDiskBlock ? media.diskSize - media.rigidDiskBlock.diskSize : media.diskSize
    parts.push({
        name: media.rigidDiskBlock ? 'Unused' : 'Disk',
        type: media.rigidDiskBlock ? 'unused' : 'disk',
        size: partSize,
        percentSize: Math.round((100 / media.diskSize) * partSize)
    })

    const partColor = (part) => {
        switch (part.type) {
            case "amiga":
                return '#008000'
            case "disk":
                return '#800080'
            case "unused":
                return '#808080'
            default:
                return '#ffff00'
        }
    }

    const renderLayout = (parts) => {
        return (
            <table style={{
                width: '100%',
                height: '100%'
            }}>
                <tbody>
                <tr style={{
                    height: '100%'
                }}>
                    {parts.map((part, index) => {
                        return (
                            <td
                                key={index}
                                width={`${part.percentSize}%`}
                                style={{height: '100%'}}
                            >
                                <div style={{
                                    border: `4px solid ${partColor(part)}`,
                                    backgroundColor: `${partColor(part)}20`,
                                    width: '100%',
                                    minWidth: part.type === 'amiga' ? '100px' : null,
                                    height: '100%',
                                    minHeight: '60px',
                                    textAlign: 'center'
                                }}>
                                    {part.type === 'amiga' && (
                                        <Stack direction="column">
                                            <span>{part.name}</span>
                                            <span>{formatBytes(part.size)}</span>
                                        </Stack>
                                    )}
                                </div>
                            </td>
                        )}
                    )}
                </tr>
                </tbody>
            </table>
        )
    }

    const renderList = (parts) => {
        return parts.map((part, index) => {
            return (
                <TableRow key={index}>
                    <TableCell>
                        <Stack direction="row">
                            <div style={{
                                border: `4px solid ${partColor(part)}`,
                                backgroundColor: `${partColor(part)}20`,
                                width: '14px',
                                height: '14px',
                                marginRight: '5px'
                            }}>
                            </div>
                            {part.name}
                        </Stack>
                    </TableCell>
                    <TableCell align="right">
                        {formatBytes(part.size)}
                    </TableCell>
                </TableRow>
            )
        })
    }
    
    return (
        <React.Fragment>
            {renderLayout(parts)}
            <TableContainer component={Paper} sx={{ mt: 1 }}>
                <Table size="small" aria-label="disk parts">
                    <TableHead>
                        <TableRow>
                            <TableCell>
                                Name
                            </TableCell>
                            <TableCell align="right">
                                Size
                            </TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {renderList(parts)}
                    </TableBody>
                </Table>
            </TableContainer>
        </React.Fragment>
    )
}