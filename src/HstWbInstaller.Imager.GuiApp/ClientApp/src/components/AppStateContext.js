import React from 'react'

export const AppStateContext = React.createContext(null)
export const AppStateDispatchContext = React.createContext(null)

function initialState() {
    return {
        isLicenseAgreed: false,
        isAdministrator: false,
        isElectronActive: false,
        useFake: false
    }
}

function appStateReducer(state, action) {
    switch (action.type) {
        case 'updateAppState': {
            return {
                ...state,
                ...action.appState
            }
        }
        default: {
            throw new Error(`Unhandled action type: ${action.type}`)
        }
    }
}

export function AppStateProvider(props) {
    const {
        children
    } = props

    const [state, dispatch] = React.useReducer(appStateReducer, {}, () => null)

    const handleAppState = React.useCallback(() => {
        async function fetchAppState() {
            const response = await fetch('api/app-state');
            const appState = response.ok ? await response.json() : initialState();
            
            dispatch({
                type: 'updateAppState',
                appState: {...appState}
            })
        }
        
        if (state) {
            return
        }

        fetchAppState()
    }, [state, dispatch])
    
    React.useEffect(() => {
        handleAppState()
    }, [handleAppState])
    
    return (
        <AppStateContext.Provider value={state}>
            <AppStateDispatchContext.Provider value={dispatch}>
                {children}
            </AppStateDispatchContext.Provider>
        </AppStateContext.Provider>
    )
}