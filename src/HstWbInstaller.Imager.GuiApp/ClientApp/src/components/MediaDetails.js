import {formatBytes} from "../utils/Format";
import {get, isNil, set} from "lodash";
import TableRow from "@mui/material/TableRow";
import TableCell from "@mui/material/TableCell";
import React from "react";
import TableContainer from "@mui/material/TableContainer";
import Paper from "@mui/material/Paper";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import Typography from "@mui/material/Typography";
import AccordionSummary from "@mui/material/AccordionSummary";
import {styled} from "@mui/material/styles";

const StyledAccordionSummary = styled(AccordionSummary)(({theme}) => ({
    padding: 0,
    color: theme.palette.primary.main
}));

export default function MediaDetails(props) {
    const {
        media
    } = props

    const [state, setState] = React.useState({});

    const handleChange = (id, expanded) => {
        set(state, id, !expanded)
        setState({...state})
    }
    
    const disk = {
        label: `Disk: ${media.model}, ${formatBytes(media.diskSize)}`,
        fields: [{
            label: 'Model',
            value: media.model
        }, {
            label: 'Path',
            value: media.path
        }, {
            label: 'Size',
            value: `${formatBytes(media.diskSize)} (${media.diskSize} bytes)`
        }]
    }

    const rigidDiskBlock = media.rigidDiskBlock ? {
        label: `Rigid disk block: ${media.rigidDiskBlock.diskProduct}, ${formatBytes(media.rigidDiskBlock.diskSize)}`,
        fields: [{
            label: 'Manufacturers Name',
            value: media.rigidDiskBlock.diskVendor
        }, {
            label: 'Drive Name',
            value: media.rigidDiskBlock.diskProduct
        }, {
            label: 'Drive Revision',
            value: media.rigidDiskBlock.diskRevision
        }, {
            label: 'Size',
            value: `${formatBytes(media.rigidDiskBlock.diskSize)} (${media.rigidDiskBlock.diskSize} bytes)`
        }, {
            label: 'Cylinders',
            value: media.rigidDiskBlock.cylinders
        }, {
            label: 'Heads',
            value: media.rigidDiskBlock.heads
        }, {
            label: 'Blocks per Track',
            value: media.rigidDiskBlock.sectors
        }, {
            label: 'Blocks per Cylinder',
            value: media.rigidDiskBlock.cylBlocks
        }, {
            label: 'Block size',
            value: media.rigidDiskBlock.blockSize
        }, {
            label: 'Park head cylinder',
            value: media.rigidDiskBlock.parkingZone
        }, {
            label: 'Start cylinder of partitionable disk area',
            value: media.rigidDiskBlock.loCylinder
        }, {
            label: 'End cylinder of partitionable disk area',
            value: media.rigidDiskBlock.hiCylinder
        }, {
            label: 'Start block reserved for RDB',
            value: media.rigidDiskBlock.rdbBlockLo
        }, {
            label: 'End block reserved for RDB',
            value: media.rigidDiskBlock.rdbBlockHi
        }]
    } : null
    
    const fileSystems = (get(media, 'rigidDiskBlock.fileSystemHeaderBlocks') || []).map((fileSystem, index) => {
        return {
            label: `File system ${(index + 1)}: ${fileSystem.dosTypeFormatted}`,
            fields: [{
                label: 'DOS Type',
                value: `${fileSystem.dosTypeHex} (${fileSystem.dosTypeFormatted})`
            }, {
                label: 'Version',
                value: fileSystem.versionFormatted
            }, {
                label: 'File system name',
                value: fileSystem.fileSystemName
            }, {
                label: 'Size',
                value: `${formatBytes(fileSystem.size)} (${fileSystem.size} bytes)`
            }]
        }
    })

    const partitions = (get(media, 'rigidDiskBlock.partitionBlocks') || []).map((partition, index) => {
        return {
            label: `Partition ${(index + 1)}: ${partition.driveName}, ${formatBytes(partition.partitionSize)}`,
            fields: [{
                label: 'Device Name',
                value: partition.driveName
            }, {
                label: 'Size',
                value: `${formatBytes(partition.partitionSize)} (${partition.partitionSize} bytes)`
            }, {
                label: 'Start Cylinder',
                value: partition.lowCyl
            }, {
                label: 'End Cylinder',
                value: partition.highCyl
            }, {
                label: 'Total Cylinders',
                value: (partition.highCyl - partition.lowCyl + 1)
            }, {
                label: 'Heads',
                value: partition.surfaces
            }, {
                label: 'Blocks per Track',
                value: partition.blocksPerTrack
            }, {
                label: 'Buffers',
                value: partition.numBuffer
            }, {
                label: 'File System Block Size',
                value: partition.fileSystemBlockSize
            }, {
                label: 'Reserved',
                value: partition.reserved
            }, {
                label: 'PreAlloc',
                value: partition.preAlloc
            }, {
                label: 'Bootable',
                value: partition.bootable ? 'Yes' : 'No'
            }, {
                label: 'Boot priority',
                value: partition.bootPriority
            }, {
                label: 'No mount',
                value: partition.noMount ? 'Yes' : 'No'
            }, {
                label: 'DOS Type',
                value: `${partition.dosTypeHex} (${partition.dosTypeFormatted})`
            }, {
                label: 'Mask',
                value: `${partition.maskHex} (${partition.mask})`
            }, {
                label: 'Max Transfer',
                value: `${partition.maxTransferHex} (${partition.maxTransfer})`
            }]
        }
    })

    let sections = [disk]
    if (rigidDiskBlock) {
        sections = sections.concat([rigidDiskBlock])
    }

    sections = sections.concat(fileSystems).concat(partitions)

    const renderFields = (fields) => {
        if (!fields) {
            return null
        }
        return fields.map((field, index) => {
            return (
                <TableRow key={index}>
                    <TableCell>
                        {field.label}
                    </TableCell>
                    <TableCell>
                        {field.value}
                    </TableCell>
                </TableRow>
            )
        })
    }
    
    return (
        <TableContainer component={Paper}>
            <Table size="small" aria-label="media details">
                <TableBody>
                    {sections.map((section, index) => {
                        const id = index.toString()
                        const expanded = isNil(state[id]) ? true : get(state , id)
                        return (
                            <React.Fragment key={index}>
                                <TableRow>
                                    <TableCell colSpan="2">
                                        <StyledAccordionSummary
                                            expandIcon={<FontAwesomeIcon icon={expanded ? 'chevron-up' : 'chevron-down'}/>}
                                            onClick={() => handleChange(index, expanded)}
                                        >
                                            <Typography>
                                                {section.label}
                                            </Typography>
                                        </StyledAccordionSummary>
                                    </TableCell>
                                </TableRow>
                                {expanded && renderFields(section.fields)}
                            </React.Fragment>
                        )}
                    )}
                </TableBody>
            </Table>
        </TableContainer>
    )
}