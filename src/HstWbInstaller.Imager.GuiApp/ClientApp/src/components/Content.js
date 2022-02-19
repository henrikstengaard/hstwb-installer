import React from 'react';
import Box from '@mui/material/Box';
import {Route} from 'react-router';
import Main from "./Main";
import Read from "../pages/Read";
import Write from "../pages/Write";
import Info from "../pages/Info";
import Convert from "../pages/Convert";
import Verify from "../pages/Verify";
import Blank from "../pages/Blank";
import Optimize from "../pages/Optimize";
import Partition from "../pages/Partition";

export default function Content() {
    return (
        <Box component="main" sx={{flexGrow: 1, marginTop: '32px', p: 3}}>
            <Route exact path='/' component={Main}/>
            <Route path='/read' component={Read}/>
            <Route path='/write' component={Write}/>
            <Route path='/info' component={Info}/>
            <Route path='/convert' component={Convert}/>
            <Route path='/verify' component={Verify}/>
            <Route path='/blank' component={Blank}/>
            <Route path='/optimize' component={Optimize}/>
            <Route path='/partition' component={Partition}/>
        </Box>
    )
}