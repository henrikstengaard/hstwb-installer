import React, { Component } from 'react';
import { Route } from 'react-router';
import { library } from '@fortawesome/fontawesome-svg-core'
import { faUpload, faDownload, faMagic, faLongArrowAltRight, faHdd, faFile, faExchangeAlt } from '@fortawesome/free-solid-svg-icons'
import Main from './components/Main'
import Read from './pages/Read'
import Write from './pages/Write'
import Convert from './pages/Convert'
import Verify from './pages/Verify'
import Blank from './pages/Blank'
import Optimize from './pages/Optimize'
import { FetchData } from './components/FetchData';
import { Counter } from './components/Counter';

import './custom.css'
import SeamlessTitlebarLayout from "components/SeamlessTitlebarLayout";

library.add(faUpload, faDownload, faMagic, faHdd, faFile, faLongArrowAltRight, faExchangeAlt)

export default class App extends Component {
    static displayName = App.name;
    
    render () {
        return (
            <SeamlessTitlebarLayout>
                <Route exact path='/' component={Main} />
                <Route path='/read' component={Read} />
                <Route path='/write' component={Write} />
                <Route path='/convert' component={Convert} />
                <Route path='/verify' component={Verify} />
                <Route path='/blank' component={Blank} />
                <Route path='/optimize' component={Optimize} />
            </SeamlessTitlebarLayout>
        );
    }
}
