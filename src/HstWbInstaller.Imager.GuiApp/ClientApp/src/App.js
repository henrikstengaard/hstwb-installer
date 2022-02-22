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
    faHome,
    faSyncAlt,
    faEllipsisH,
    faBan,
    faInfo,
    faArrowLeft,
    faTimes
} from '@fortawesome/free-solid-svg-icons'
import Box from '@mui/material/Box'
import CssBaseline from '@mui/material/CssBaseline'
import ProgressBackdrop from "./components/ProgressBackdrop"
import './custom.css'
import Titlebar from "./components/Titlebar";
import Navigation from "./components/Navigation";
import Content from "./components/Content";
import {ProgressProvider} from "./components/ProgressContext";
import ErrorSnackBar from "./components/ErrorSnackBar";

library.add(faUpload, faDownload, faMagic, faHdd, faFile, faLongArrowAltRight, 
    faExchangeAlt, faBars, faWindowMinimize, faWindowMaximize, faWindowRestore, faWindowClose,
    faChevronLeft,
    faChevronRight,
    faCheck,
    faPlus,
    faQuestion,
    faHome,
    faSyncAlt,
    faEllipsisH,
    faBan,
    faInfo,
    faArrowLeft,
    faTimes)

export default class App extends Component {
    static displayName = App.name;

    render() {
        return (
            <Box sx={{ display: 'flex' }}>
                <CssBaseline />
                <Titlebar />
                <ProgressProvider>
                    <ProgressBackdrop>
                        <ErrorSnackBar />
                        <Navigation />
                        <Content />
                    </ProgressBackdrop>
                </ProgressProvider>
            </Box>
        );
    }
}
