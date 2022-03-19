import { get, set } from "lodash"
import Title from "../components/Title"
import React from "react"
import Grid from "@mui/material/Grid"
import SelectField from "../components/SelectField"
import {AppStateContext} from "../components/AppStateContext"
import {AppStateDispatchContext} from "../components/AppStateContext"

export default function Settings() {
    const appState = React.useContext(AppStateContext)
    const appStateDispatch = React.useContext(AppStateDispatchContext)

    const isMacOs = get(appState, 'isMacOs') || false
    const settings = get(appState, 'settings') || {}
    
    const saveSettings = async ({ name, value} = {}) => {
        set(settings, name, value)
        
        const response = await fetch('api/settings', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({...settings})
        });
        if (!response.ok) {
            console.error('Failed to save settings')
        }

        appStateDispatch({
            type: 'updateAppState',
            appState: {
                ...appState,
                settings: {...settings}
            }
        })
    }
    
    const macOsElevateMethodOptions = [{
        title: 'Osascript sudo',
        value: 'OsascriptSudo'
    },{
        title: 'Osascript administrator privileges',
        value: 'OsascriptAdministrator'
    }]
    
    const {
        macOsElevateMethod = 'osascriptSudo'
    } = settings
    
    return (
        <React.Fragment>
            <Title
                text="Settings"
            />
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
                    <SelectField
                        label="macOS elevate method"
                        id="macos-elevate-method"
                        disabled={!isMacOs}
                        value={macOsElevateMethod || ''}
                        options={macOsElevateMethodOptions}
                        onChange={async (value) => await saveSettings({ name: 'macOsElevateMethod', value })}
                    />
                </Grid>
            </Grid>
        </React.Fragment>
    )
}