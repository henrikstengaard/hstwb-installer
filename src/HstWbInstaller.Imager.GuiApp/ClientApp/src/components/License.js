import Paper from "@mui/material/Paper";
import Box from "@mui/material/Box";
import {Button} from "@mui/material";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import React from "react";
import {AppStateContext, AppStateDispatchContext} from "./AppStateContext";
import Container from "@mui/material/Container";
import Title from "./Title";
import Stack from "@mui/material/Stack";

export default function License(props) {
    const appState = React.useContext(AppStateContext)
    const appStateDispatch = React.useContext(AppStateDispatchContext)

    const {
        children
    } = props
    
    if (!appState) {
        return children
    }
    
    const {
        isLicenseAgreed
    } = appState
    
    if (isLicenseAgreed) {
        return children
    }
    
    const handleAgree = async (agree) => {
        const response = await fetch('api/license', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                licenseAgreed: agree,
            })
        });
        if (!response.ok) {
            console.error('Failed to send license')
        }
        appStateDispatch({
            type: 'updateAppState',
            appState: {
                ...appState,
                isLicenseAgreed: agree
            }
        })
    }
    
    return (
        <Container>
            <Box sx={{
                display: 'flex',
                justifyContent: 'center',
            }}
                style={{ marginTop: '50px' }}
            >
                <Title text="License" />
            </Box>
            <Paper sx={{ p: 1 }}>
                <p>
                    Copyright 2022 Henrik Nørfjand Stengaard
                </p>
                <p>
                    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
                </p>
                <p>
                    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
                </p>
                <p>
                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                </p>
            </Paper>
            <Box sx={{
                m: 1,
                display: 'flex',
                justifyContent: 'center'
            }}>
                <Stack direction="row" spacing={2} sx={{mt: 2}}>
                    <Button
                        variant="contained"
                        startIcon={<FontAwesomeIcon icon="ban"/>}
                        onClick={() => handleAgree(false)}
                    >
                        Disagree
                    </Button>
                    <Button
                        variant="contained"
                        startIcon={<FontAwesomeIcon icon="check"/>}
                        onClick={() => handleAgree(true)}
                    >
                        Agree
                    </Button>
                </Stack>
            </Box>
        </Container>
    )
}