import React from 'react'
import Box from '@mui/material/Box';
import InputLabel from '@mui/material/InputLabel';
import MenuItem from '@mui/material/MenuItem';
import FormControl from '@mui/material/FormControl';
import Select from '@mui/material/Select'
import {Table, TableHead} from "@mui/material";

export default function Main() {
    const handleChangeSource = () =>{
        
    }
    
    return (
        <Box sx={{minWidth: 120}}>
            <h2>Read</h2>
            <FormControl fullWidth>
                <InputLabel id="source-label">Source</InputLabel>
                <Select
                    labelId="source-label"
                    id="source"
                    value={null}
                    label="Source"
                    onChange={handleChangeSource}
                >
                    <MenuItem value={10}>Ten</MenuItem>
                    <MenuItem value={20}>Twenty</MenuItem>
                    <MenuItem value={30}>Thirty</MenuItem>
                </Select>
            </FormControl>
            <Table style={{ width: '100%' }}>
                <tr>
                    <td width="10%" style={{backgroundColor: 'green'}}>DH0:</td>
                    <td width="90%" style={{backgroundColor: 'yellow'}}>DH1:</td>
                </tr>
            </Table>
        </Box>
    )
}