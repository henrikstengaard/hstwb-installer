import React from 'react'
import { Link, withRouter, RouteComponentProps } from "react-router-dom";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCoffee } from '@fortawesome/free-solid-svg-icons'
import { faHdd } from '@fortawesome/free-solid-svg-icons'
import { faBox } from '@fortawesome/free-solid-svg-icons'
import { faMicrochip } from '@fortawesome/free-solid-svg-icons'
import Drawer from '@material-ui/core/Drawer'
import List from '@material-ui/core/List'
import ListItem from '@material-ui/core/ListItem'
import ListItemText from '@material-ui/core/ListItemText'
import ListItemIcon from '@material-ui/core/ListItemIcon'


interface IProps extends RouteComponentProps {
    classes: any
}
class Menu extends React.Component<IProps> {
    render() {
        const menuItems = [
            {
                label: 'Project',
                link: '/project',
                icon: <FontAwesomeIcon icon={faCoffee} />,
            },
            {
                label: 'Image',
                link: '/image',
                icon: <FontAwesomeIcon icon={faHdd} />,
            },
            {
                label: 'Amiga OS',
                link: '/amiga-os',
                icon: <FontAwesomeIcon icon={faCoffee} />,
            },
            {
                label: 'Kickstart',
                link: '/kickstart',
                icon: <FontAwesomeIcon icon={faMicrochip} />,
            },
            {
                label: 'Packages',
                link: '/packages',
                icon: <FontAwesomeIcon icon={faBox} />,
            },
            {
                label: 'User Packages',
                link: '/user-packages',
                icon: <FontAwesomeIcon icon={faBox} />,
            },
        ]
        return (
            <Drawer
            className={this.props.classes.drawer}
            variant="permanent"
            classes={{
                paper: this.props.classes.drawerPaper,
            }}
            anchor="left"
            >
            <List>
                {menuItems.map((menuItem) => {
                    return (
                        <ListItem button key={menuItem.label} component={Link} to={menuItem.link}>
                            <ListItemIcon>{menuItem.icon}</ListItemIcon>
                            <ListItemText primary={menuItem.label} />
                        </ListItem>
                )})
                }
            </List>
            </Drawer>
        )
    }
}

export default withRouter(Menu)
