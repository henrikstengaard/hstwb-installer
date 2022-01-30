import React, {Component} from 'react';
import {library} from '@fortawesome/fontawesome-svg-core'
import {
    faUpload,
    faDownload,
    faMagic,
    faLongArrowAltRight,
    faHdd,
    faFile,
    faExchangeAlt,
    faBars,
    faWindowMinimize,
    faWindowMaximize,
    faWindowRestore,
    faWindowClose,
    faChevronLeft,
    faChevronRight,
    faCheck,
    faPlus,
    faQuestion,
    faHome
} from '@fortawesome/free-solid-svg-icons'
import Box from '@mui/material/Box'
import CssBaseline from '@mui/material/CssBaseline'
import GlobalStyles from '@mui/material/GlobalStyles'
import { BrowserRouter } from 'react-router-dom'
import Main from './components/Main'
import Read from './pages/Read'
import Write from './pages/Write'
import Convert from './pages/Convert'
import Verify from './pages/Verify'
import Blank from './pages/Blank'
import Optimize from './pages/Optimize'
import {FetchData} from './components/FetchData';
import {Counter} from './components/Counter';

import './custom.css'
import Titlebar from "./components/Titlebar";
import Navigation from "./components/Navigation";
import Content from "./components/Content";

library.add(faUpload, faDownload, faMagic, faHdd, faFile, faLongArrowAltRight, 
    faExchangeAlt, faBars, faWindowMinimize, faWindowMaximize, faWindowRestore, faWindowClose,
    faChevronLeft,
    faChevronRight,
    faCheck,
    faPlus,
    faQuestion,
    faHome)

export default class App extends Component {
    static displayName = App.name;

    render() {
        return (
            <Box sx={{ display: 'flex' }}>
                <CssBaseline />
                <GlobalStyles styles={{ h2: { marginTop: '0' } }} />
                <Titlebar />
                <Navigation />
                <Content />
            </Box>
        );
    }
}
