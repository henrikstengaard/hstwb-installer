import React from 'react'
import { Route, BrowserRouter, Switch } from 'react-router-dom'
import Start from './components/Start'
import Project from './components/Project'
import Image from './components/Image'
import AmigaOs from './components/AmigaOs'
import Kickstart from './components/Kickstart'
import Packages from './components/Packages'
import UserPackages from './components/UserPackages'
import Notfound from './components/NotFound'
import Menu from './components/Menu'

interface IProps {
    classes: any
}
const router = ({classes}: IProps) => (
    <BrowserRouter>
        <Menu classes={classes} />
        <main className={classes.content}>
            <Switch>
                <Route exact path="/" component={Start} />
                <Route path="/project" component={Project} />
                <Route path="/image" component={Image} />
                <Route path="/amiga-os" component={AmigaOs} />
                <Route path="/kickstart" component={Kickstart} />
                <Route path="/packages" component={Packages} />
                <Route path="/user-packages" component={UserPackages} />
                <Route component={Notfound} />
            </Switch>
        </main>
    </BrowserRouter>
)

export default router
