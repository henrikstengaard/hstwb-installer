import './index.css'
import React from 'react'
import ReactDOM from 'react-dom'
import { BrowserRouter } from 'react-router-dom'
import { createTheme, ThemeProvider as MuiThemeProvider } from '@mui/material'
import App from './App'
import registerServiceWorker from './registerServiceWorker'

const baseUrl = document.getElementsByTagName('base')[0].getAttribute('href');
const rootElement = document.getElementById('root');
const theme = createTheme({
    typography: {
        fontFamily: [
            'topazplus_a600a1200a4000Rg',
            'Segoe UI',            
            'sans-serif',
        ].join(','),
        h6: {
            fontSize: '14px'
        },
    },
})

ReactDOM.render(
    <MuiThemeProvider theme={theme}>
        <BrowserRouter basename={baseUrl}>
            <App />
        </BrowserRouter>
    </MuiThemeProvider>,
    rootElement);

registerServiceWorker();

