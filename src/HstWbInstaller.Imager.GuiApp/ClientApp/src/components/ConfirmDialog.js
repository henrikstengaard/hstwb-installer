import { isNil } from 'lodash'
import React from 'react'
import Dialog from '@mui/material/Dialog'
import DialogActions from '@mui/material/DialogActions'
import DialogContent from '@mui/material/DialogContent'
import DialogContentText from '@mui/material/DialogContentText'
import DialogTitle from '@mui/material/DialogTitle'
import Paper from '@mui/material/Paper'
import Button from "./Button";

export default function ConfirmDialog(props) {
    const {
        children,
        component: Component,
        fullWidth = false,
        id,
        maxWidth = 'sm',
        open,
        title,
        description,
        hasCancel = true,
        centerActions = false,
        onClose
    } = props

    const handleClose = (confirmed) => {
        if (isNil(onClose)) {
            return
        }
        onClose(confirmed)
    }

    const dialogId = `${id}-dialog`
    const content = (
        <React.Fragment>
            {!isNil(title) && (
                <DialogTitle id={dialogId}>
                    {title}
                </DialogTitle>
            )}
            <DialogContent>
                {!isNil(description) && (
                    <DialogContentText>
                        {description}
                    </DialogContentText>
                )}
                {children}
            </DialogContent>
            <DialogActions style={{justifyContent: centerActions ? 'center' : null}}>
                {hasCancel && (
                    <Button
                        icon="ban"
                        onClick={() => handleClose(false)}
                    >
                        Cancel
                    </Button>
                )}
                <Button
                    icon="check"
                    onClick={() => handleClose(true)}
                >
                    OK
                </Button>
            </DialogActions>
        </React.Fragment>
    )

    return (
        <Dialog
            fullWidth={fullWidth}
            maxWidth={maxWidth}
            open={open}
            onClose={() => handleClose(false)}
            PaperComponent={Paper}
            aria-labelledby={dialogId}
        >
            {isNil(Component) ? content : (
                <Component>
                    {content}
                </Component>
            )}
        </Dialog>
    )
}