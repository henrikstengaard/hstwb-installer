import React from 'react'
import {useHistory} from 'react-router-dom'
import { styled, useTheme } from '@mui/material/styles';
import Box from '@mui/material/Box';
import MuiDrawer from '@mui/material/Drawer';
import List from '@mui/material/List';
import CssBaseline from '@mui/material/CssBaseline';
import Toolbar from '@mui/material/Toolbar';
import Divider from '@mui/material/Divider';
import IconButton from '@mui/material/IconButton';
// import MenuIcon from '@mui/icons-material/Menu';
// import ChevronLeftIcon from '@mui/icons-material/ChevronLeft';
// import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import ListItem from '@mui/material/ListItem';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
// import InboxIcon from '@mui/icons-material/MoveToInbox';
// import MailIcon from '@mui/icons-material/Mail';
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'

const drawerOpenWidth = 160;
const drawerClosedWidth = 50;

const openedMixin = (theme) => ({
    width: drawerOpenWidth,
    transition: theme.transitions.create('width', {
        easing: theme.transitions.easing.sharp,
        duration: theme.transitions.duration.enteringScreen,
    }),
    overflowX: 'hidden',
});

const closedMixin = (theme) => ({
    transition: theme.transitions.create('width', {
        easing: theme.transitions.easing.sharp,
        duration: theme.transitions.duration.shortest,
    }),
    overflowX: 'hidden',
    // width: `calc(${theme.spacing(7)} + 1px)`,
    // [theme.breakpoints.up('sm')]: {
    //     width: `calc(${theme.spacing(9)} + 1px)`,
    // },
});

const Drawer = styled(MuiDrawer, { shouldForwardProp: (prop) => prop !== 'open' })(
    ({ theme, open }) => ({
        width: drawerOpenWidth,
        flexShrink: 0,
        whiteSpace: 'nowrap',
        boxSizing: 'border-box',
        ...(open && {
            ...openedMixin(theme),
            '& .MuiDrawer-paper': openedMixin(theme),
        }),
        ...(!open && {
            ...closedMixin(theme),
            '& .MuiDrawer-paper': closedMixin(theme),
        }),
    }),
);

export default function Navigation() {
    const history = useHistory()
    const theme = useTheme();
    const [open, setOpen] = React.useState(false);

    const handleDrawerOpen = () => {
        setOpen(true);
    };

    const handleDrawerClose = () => {
        setOpen(false);
    };
    
    const items = [
        {
            text: 'Main',
            icon: 'home',
            path: '/'
        },
        {
            text: 'Read',
            icon: 'upload',
            path: '/read'
        },
        {
            text: 'Write',
            icon: 'download',
            path: '/write'
        },
        {
            text: 'Convert',
            icon: 'exchange-alt',
            path: '/convert'
        },
        {
            text: 'Verify',
            icon: 'check',
            path: '/verify'
        },
        {
            text: 'Blank',
            icon: 'plus',
            path: '/blank'
        },
        {
            text: 'Optimize',
            icon: 'magic',
            path: '/optimize'
        },
        {
            text: 'About',
            icon: 'question',
            path: '/about'
        },
    ]
    
    const handleOpen = () => {
        setOpen(!open)
    }
    
    const handleRedirect = (path) => history.push(path)
    const width = `${open ? drawerOpenWidth : drawerClosedWidth}px`
    
    return (
        <Drawer position="fixed" open={open} variant="permanent"
                sx={{
                    width,
                    overflowX: 'hidden',
                    [`& .MuiDrawer-paper`]: { width, boxSizing: 'border-box' },
                }}>
            <List sx={{marginTop: '32px'}}>
                {items.map((item, index) => (
                    <ListItem button key={index} onClick={() => handleRedirect(item.path)}>
                        <ListItemIcon>
                            <FontAwesomeIcon icon={item.icon}/>
                        </ListItemIcon>
                        <ListItemText primary={item.text} />
                    </ListItem>
                ))}
            </List>
            <Box sx={{flexGrow: 1 }} />
            <List >
                <ListItem button onClick={() => handleOpen()} sx={{ width: '100%'}}>
                    <ListItemIcon >
                        <FontAwesomeIcon icon={open ? 'chevron-left' : 'chevron-right'}/>
                    </ListItemIcon>
                </ListItem>
            </List>
        </Drawer>
    )
}