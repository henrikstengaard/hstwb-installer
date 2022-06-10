import React from "react";
import Stack from "@mui/material/Stack";
import {formatBytes} from "../utils/Format";
import TableContainer from "@mui/material/TableContainer";
import Paper from "@mui/material/Paper";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableRow from "@mui/material/TableRow";
import TableCell from "@mui/material/TableCell";
import {TableHead} from "@mui/material";

export default function RigidDiskBlockOverview(props) {
    const {
        rigidDiskBlock
    } = props

    const minimum = (value) => value < 1 ? 1 : value

    const cylinderSize = rigidDiskBlock.heads * rigidDiskBlock.sectors * rigidDiskBlock.blockSize;

    const rdbBlockLoCylinder = Math.round((rigidDiskBlock.rdbBlockLo * rigidDiskBlock.blockSize) / cylinderSize);
    const rdbBlockHiCylinder = Math.round((rigidDiskBlock.rdbBlockHi * rigidDiskBlock.blockSize) / cylinderSize);
    const rdbBlockCylinders = minimum(rdbBlockHiCylinder - rdbBlockLoCylinder + 1)

    const partitions = []

    rigidDiskBlock.partitionBlocks.forEach((partitionBlock) => {
        partitions.push({
            name: partitionBlock.driveName,
            fileSystem: partitionBlock.dosTypeFormatted,
            type: 'partition',
            start: partitionBlock.lowCyl,
            end: partitionBlock.highCyl,
            size: partitionBlock.partitionSize,
            percentSize: Math.round((100 / rigidDiskBlock.cylinders) * (partitionBlock.highCyl - partitionBlock.lowCyl + 1))
        })
    })

    partitions.push({
        name: 'RDB',
        type: 'rdb',
        start: rdbBlockLoCylinder,
        end: rdbBlockHiCylinder,
        size: rdbBlockCylinders * cylinderSize,
        percentSize: Math.round((100 / rigidDiskBlock.cylinders) * rdbBlockCylinders)
    })

    partitions.sort(function(a, b){return a.start - b.start})

    let currentStart = 0;
    partitions.forEach((partition) => {
        if (partition.start > currentStart) {
            const unusedCylinders = partition.start - 1 - currentStart
            partitions.push({
                name: 'Unallocated',
                type: 'unallocated',
                start: currentStart,
                end: unusedCylinders,
                size: unusedCylinders * cylinderSize,
                percentSize: Math.round((100 / rigidDiskBlock.cylinders) * unusedCylinders)
            })
        }
        currentStart = partition.end + 1
    })

    if (currentStart < rigidDiskBlock.cylinders)
    {
        const unusedCylinders = rigidDiskBlock.cylinders - currentStart + 1
        partitions.push({
            name: 'Unallocated',
            type: 'unallocated',
            start: currentStart,
            end: rigidDiskBlock.cylinders,
            size: unusedCylinders * cylinderSize,
            percentSize: Math.round((100 / rigidDiskBlock.cylinders) * unusedCylinders)
        })
    }

    partitions.sort(function(a, b){return a.start - b.start})
    
    const partColor = (part) => {
        switch (part.type) {
            case "rdb":
                return '#008000'
            case "partition":
                return '#800080'
            case "unallocated":
                return '#808080'
            default:
                return '#ffff00'
        }
    }

    const renderLayout = (partitions) => {
        return (
            <table style={{
                width: '100%',
                height: '100%'
            }}>
                <tbody>
                <tr style={{
                    height: '100%'
                }}>
                    {partitions.map((partition, index) => {
                        return (
                            <td
                                key={index}
                                width={`${partition.percentSize}%`}
                                style={{height: '100%'}}
                            >
                                <div style={{
                                    border: `4px solid ${partColor(partition)}`,
                                    backgroundColor: `${partColor(partition)}20`,
                                    width: '100%',
                                    minWidth: partition.type === 'partition' ? '100px' : null,
                                    height: '100%',
                                    minHeight: '60px',
                                    textAlign: 'center'
                                }}>
                                    {partition.type === 'partition' && (
                                        <Stack direction="column">
                                            <span>{partition.name}</span>
                                            <span>{formatBytes(partition.size)}</span>
                                            <span>{partition.fileSystem}</span>
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
    
    const renderList = (partitions) => {
        return partitions.map((partition, index) => {
            return (
                <TableRow key={index}>
                    <TableCell>
                        <Stack direction="row">
                            <div style={{
                                border: `4px solid ${partColor(partition)}`,
                                backgroundColor: `${partColor(partition)}20`,
                                width: '14px',
                                height: '14px',
                                marginRight: '5px'
                            }}>
                            </div>
                            {partition.name}
                        </Stack>
                    </TableCell>
                    <TableCell align="right">
                        {formatBytes(partition.size)}
                    </TableCell>
                    <TableCell>
                        {partition.type === 'partition' ? partition.fileSystem : ''}
                    </TableCell>
                </TableRow>
            )
        })
    }
    
    return (
        <React.Fragment>
            {renderLayout(partitions)}
            <TableContainer component={Paper} sx={{ mt: 1 }}>
                <Table size="small" aria-label="rigid disk block partitions">
                    <TableHead>
                        <TableRow>
                            <TableCell>
                                Partition
                            </TableCell>
                            <TableCell align="right">
                                Size
                            </TableCell>
                            <TableCell>
                                File system
                            </TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {renderList(partitions)}
                    </TableBody>
                </Table>
            </TableContainer>
        </React.Fragment>
    )
}