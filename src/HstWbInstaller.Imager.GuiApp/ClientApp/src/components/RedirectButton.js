import React from 'react'
import {useHistory} from 'react-router-dom'
import Button from "../components/Button"
import {isNil} from "lodash"

export default function RedirectButton(props) {
    const history = useHistory()

    const {
        icon,
        path,
        children,
        onClick
    } = props

    const handleRedirect = (path) => {
        if (!isNil(onClick)) {
            onClick()
        }
        history.push(path)
    }
    
    return (
        <Button
            icon={icon}
            onClick={() => handleRedirect(path)}
        >
            {children}
        </Button>
    )
}

