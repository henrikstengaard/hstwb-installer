import React from 'react'

export const ProgressStateContext = React.createContext(null)
export const ProgressDispatchContext = React.createContext(null)

function initialState() {
    return {
        title: null,
        show: false,
        percentComplete: null
    };
}

function progressReducer(state, action) {
    switch (action.type) {
        case 'updateProgress': {
            return {
                ...state,
                ...action.progress
            }
        }
        default: {
            throw new Error(`Unhandled action type: ${action.type}`)
        }
    }
}

export function ProgressProvider(props) {
    const {
        children
    } = props

    const [state, dispatch] = React.useReducer(progressReducer, {}, initialState)
    
    return (
        <ProgressStateContext.Provider value={state}>
            <ProgressDispatchContext.Provider value={dispatch}>
                {children}
            </ProgressDispatchContext.Provider>
        </ProgressStateContext.Provider>
    )
}