import React from "react";
// import Table from '@mui/material/Table';
// import TableBody from '@mui/material/TableBody';
// import TableCell from '@mui/material/TableCell';
// import TableContainer from '@mui/material/TableContainer';
// import TableHead from '@mui/material/TableHead';
// import TableRow from '@mui/material/TableRow';
// import Paper from '@mui/material/Paper';
import PropTypes from 'prop-types';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import Typography from "@mui/material/Typography";
import {formatBytes} from "../utils/Format";
import Box from "@mui/material/Box";

function TabPanel(props) {
    const { children, value, index, ...other } = props;

    return (
        <div
            role="tabpanel"
            hidden={value !== index}
            id={`simple-tabpanel-${index}`}
            aria-labelledby={`simple-tab-${index}`}
            {...other}
        >
            {value === index && (
                <Box sx={{ p: 3 }}>
                    <Typography>{children}</Typography>
                </Box>
            )}
        </div>
    );
}

TabPanel.propTypes = {
    children: PropTypes.node,
    index: PropTypes.number.isRequired,
    value: PropTypes.number.isRequired,
};

function a11yProps(index) {
    return {
        id: `simple-tab-${index}`,
        'aria-controls': `simple-tabpanel-${index}`,
    };
}

export default function Media({media} = {}) {
    const [value, setValue] = React.useState(0);

    const handleChange = (event, newValue) => {
        setValue(newValue);
    };

    console.log(media)
    
    // const partitions = media.rigidDiskBlock.partitionBlocks.map(partitionBlock => ({
    //     percentSize: Math.round((100.0 / media.rigidDiskBlock.diskSize) * partitionBlock.partitionSize),
    //     driveName: partitionBlock.driveName
    // }))

    const unusedBytes = media.rigidDiskBlock ? media.diskSize - media.rigidDiskBlock.diskSize : 0
    const disk = {
        rigidDiskBlockPercentSize: media.rigidDiskBlock ? Math.round((100.0 / media.diskSize) * media.rigidDiskBlock.diskSize) : 0,
        percentUnused: unusedBytes > 0 ? Math.round((100.0 / media.diskSize) * unusedBytes) : 0,
        unusedBytes
    }
    
    const rigidDiskBlock = media.rigidDiskBlock ? {
        name: media.rigidDiskBlock.diskProduct ? media.rigidDiskBlock.diskProduct : '',
        size: media.rigidDiskBlock.diskSize,
        partitions: media.rigidDiskBlock.partitionBlocks.map(partitionBlock => ({
            percentSize: Math.round((100.0 / media.rigidDiskBlock.diskSize) * partitionBlock.partitionSize),
            fileSystem: partitionBlock.dosTypeFormatted,
            name: partitionBlock.driveName,
            size: partitionBlock.partitionSize
        }))
    } : null
    
    console.log(rigidDiskBlock)
    return (
        <Box sx={{ width: '100%' }}>
            <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
                <Tabs value={value} onChange={handleChange} aria-label="information tabs">
                    <Tab label="Overview" {...a11yProps(0)} />
                    <Tab label="Details" {...a11yProps(1)} />
                </Tabs>
            </Box>
            {/*<TableContainer component={Paper}>*/}
            {/*    <Table sx={{minWidth: 650}} size="small" aria-label="simple table">*/}
            {/*        <TableHead>*/}
            {/*            <TableRow>*/}
            {/*                <TableCell width="50px" />*/}
            {/*                <TableCell>Type</TableCell>*/}
            {/*                <TableCell>Name</TableCell>*/}
            {/*                <TableCell>File system</TableCell>*/}
            {/*                <TableCell>Capacity</TableCell>*/}
            {/*            </TableRow>*/}
            {/*        </TableHead>*/}
            {/*        <TableBody>*/}
            {/*            <TableRow>*/}
            {/*                <TableCell width="50px">*/}
            {/*                    <FontAwesomeIcon icon="hdd"/>*/}
            {/*                </TableCell>*/}
            {/*                <TableCell>*/}
            {/*                    Disk*/}
            {/*                </TableCell>*/}
            {/*                <TableCell>*/}
            {/*                    {media.model}*/}
            {/*                </TableCell>*/}
            {/*                <TableCell />*/}
            {/*                <TableCell>{formatBytes(media.diskSize)}</TableCell>*/}
            {/*            </TableRow>*/}
            {/*            <TableRow>*/}
            {/*                <TableCell width="50px">*/}
            {/*                    <img src="icons/amiga-check-logo.png" height="14px" />*/}
            {/*                </TableCell>*/}
            {/*                <TableCell>*/}
            {/*                    Rigid Disk Block*/}
            {/*                </TableCell>*/}
            {/*                <TableCell>*/}
            {/*                    {rigidDiskBlock.name}*/}
            {/*                </TableCell>*/}
            {/*                <TableCell/>*/}
            {/*                <TableCell>{formatBytes(rigidDiskBlock.size)}</TableCell>*/}
            {/*            </TableRow>*/}
            {/*            {rigidDiskBlock.partitions.map((partition, index) => (*/}
            {/*                <TableRow key={index}>*/}
            {/*                    <TableCell width="50px">*/}
            {/*                        <img src="icons/amiga-check-logo.png" height="14px" alt="Amiga logo" />*/}
            {/*                    </TableCell>*/}
            {/*                    <TableCell>*/}
            {/*                        {`Partition ${index + 1}`}*/}
            {/*                    </TableCell>*/}
            {/*                    <TableCell>*/}
            {/*                        {partition.name}*/}
            {/*                    </TableCell>*/}
            {/*                    <TableCell>{partition.fileSystem}</TableCell>*/}
            {/*                    <TableCell>{formatBytes(partition.size)}</TableCell>*/}
            {/*                </TableRow>*/}
            {/*            ))}*/}
            {/*        </TableBody>*/}
            {/*    </Table>*/}
            {/*</TableContainer>*/}
            <TabPanel value={value} index={0}>
                <Typography variant="h4">
                    Disk information
                </Typography>
                <table style={{width: '100%', display: 'inline-table', border: '1px solid black', borderCollapse: 'collapse'}}>
                    <tbody>
                    <tr>
                        <td
                            colSpan={disk.unusedBytes > 0 ? 2 : 1}
                            style={{padding: '5px', border: '1px solid black', verticalAlign: 'top' }}
                        >
                            <FontAwesomeIcon icon="hdd" style={{verticalAlign: 'text-top' }}/> Disk, {media.model}, {formatBytes(media.diskSize)}
                        </td>
                    </tr>
                    <tr>
                        {rigidDiskBlock && (
                            <td
                                width={`${disk.rigidDiskBlockPercentSize}%`}
                                style={{padding: '5px', border: '1px solid black', verticalAlign: 'top' }}
                            >
                                <div style={{backgroundColor: 'rgb(210,210,255)', width: '100%', height: '20px'}}/>
                                <img src="icons/amiga-check-logo.png" height="14px" alt="Amiga logo" style={{verticalAlign: 'text-top' }} /> RDB, {rigidDiskBlock.name}, {formatBytes(rigidDiskBlock.size)}
                            </td>
                        )}
    
                        {!rigidDiskBlock && (
                            <td
                                width="100%"
                                style={{padding: '5px', border: '1px solid black', verticalAlign: 'top' }}
                            >
                                <div style={{backgroundColor: 'rgb(210,210,255)', width: '100%', height: '20px'}}/>
                            </td>
                        )}
    
                        {disk.unusedBytes > 0 && (
                            <td
                                width={`${disk.percentUnused}%`}
                                style={{padding: '5px', border: '1px solid black', verticalAlign: 'top' }}
                            >
                                <div style={{backgroundColor: 'rgb(200,200,200)', width: '100%', height: '20px'}}/>
                                Unused, {formatBytes(disk.unusedBytes)}
                            </td>
                        )}                    
                    </tr>
                    </tbody>
                </table>
    
                {rigidDiskBlock && (
                    <React.Fragment>
                        <Typography variant="h4" sx={{ mt: 1 }}>
                            Rigid Disk Block information
                        </Typography>
                        <table style={{width: '100%', display: 'inline-table', border: '1px solid black', borderCollapse: 'collapse'}}>
                            <tbody>
                            <tr>
                                <td
                                    colSpan={rigidDiskBlock.partitions.length}
                                    style={{padding: '5px', border: '1px solid black', verticalAlign: 'top' }}
                                >
                                    <img src="icons/amiga-check-logo.png" height="14px" alt="Amiga logo" style={{verticalAlign: 'text-top' }} /> RDB, {rigidDiskBlock.name}, {formatBytes(rigidDiskBlock.size)}
                                </td>
                            </tr>
                            {rigidDiskBlock.partitions.length > 0 && (
                                <React.Fragment>
                                    <tr>
                                        {rigidDiskBlock.partitions.map((partition, index) => (
                                            <td
                                                key={index}
                                                width={`${partition.percentSize}%`}
                                                style={{padding: '5px', border: '1px solid black', verticalAlign: 'top' }}
                                            >
                                                <div style={{backgroundColor: 'rgb(210,210,255)', width: '100%', height: '20px', padding: '1px'}}>{partition.name}</div>
                                                {/*{partition.name}, {partition.fileSystem}, {formatBytes(partition.size)}*/}
                                            </td>
                                        ))}
                                    </tr>
                                    {rigidDiskBlock.partitions.map((partition, index) => (
                                        <tr key={index}>
                                            <td colSpan={rigidDiskBlock.partitions.length}>
                                                {partition.name}:, {partition.fileSystem}, {formatBytes(partition.size)}
                                            </td>
                                        </tr>
                                    ))}
                                </React.Fragment>
                            )}
                            </tbody>
                        </table>
                    </React.Fragment>
                )}
            </TabPanel>
            <TabPanel value={value} index={1}>
                details
            </TabPanel>
        </Box>            
    )
}