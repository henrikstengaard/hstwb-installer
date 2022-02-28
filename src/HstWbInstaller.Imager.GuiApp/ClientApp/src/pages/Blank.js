import React from 'react'
import Box from "@mui/material/Box";
import Title from "../components/Title";
import Grid from "@mui/material/Grid";
import TextField from "../components/TextField";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import BrowseSaveDialog from "../components/BrowseSaveDialog";
import {get, isNil, set} from "lodash";
import Stack from "@mui/material/Stack";
import RedirectButton from "../components/RedirectButton";
import Button from "../components/Button";
import SelectField from "../components/SelectField";
import CheckboxField from "../components/CheckboxField";

const initialState = {
    path: null,
    size: 16,
    unit: 'gb',
    compatibleSize: true
}

const unitOptions = [{
    title: 'GB',
    value: 'gb',
    size: Math.pow(10, 9)
},{
    title: 'MB',
    value: 'mb',
    size: Math.pow(10, 6)
},{
    title: 'KB',
    value: 'kb',
    size: Math.pow(10, 3)
},{
    title: 'bytes',
    value: 'bytes',
    size: 0
}]

export default function Blank() {
    const [state, setState] = React.useState({ ...initialState })

    const {
        path,
        size,
        unit,
        compatibleSize
    } = state
    
    const handleBlank = async () => {
        const unitOption = unitOptions.find(x => x.value === unit)
        const response = await fetch('api/blank', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                title: `Creating ${size} ${unitOption.title} blank image '${path}'`,
                path,
                size: (size * unitOption.size),
                unit,
                compatibleSize
            })
        });

        state.path = path
        setState({...state,})

        if (!response.ok) {
            console.error('Failed to create blank')
        }
    }
    
    const handleChange = ({name, value}) => {
        set(state, name, value)
        setState({...state})
    }

    const handleCancel = () => {
        setState({ ...initialState })
    }
    
    const blankDisabled = isNil(path) || size <= 0
    
    return (
        <Box>
            <Title
                text="Blank"
                description="Create blank image file."
            />
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
                    <TextField
                        id="image-path"
                        label={
                            <div style={{display: 'flex', alignItems: 'center', verticalAlign: 'bottom'}}>
                                <FontAwesomeIcon icon="file" style={{marginRight: '5px'}} /> Image file
                            </div>
                        }
                        value={path || ''}
                        endAdornment={
                            <BrowseSaveDialog
                                id="browse-image-path"
                                title="Select image file to create"
                                onChange={(path) => handleChange({
                                    name: 'path',
                                    value: path
                                })}
                            />
                        }
                        onChange={(event) => handleChange({
                            name: 'path',
                            value: get(event, 'target.value'
                            )}
                        )}
                        onKeyDown={async (event) => {
                            if (event.key !== 'Enter') {
                                return
                            }
                            await handleBlank()
                        }}
                    />
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={8} lg={4}>
                    <TextField
                        label="Size"
                        id="size"
                        type="number"
                        value={size}
                        inputProps={{min: 0, style: { textAlign: 'right' }}}
                        onChange={(event) => handleChange({
                            name: 'size',
                            value: event.target.value
                        })}
                        onKeyDown={async (event) => {
                            if (event.key !== 'Enter') {
                                return
                            }
                            await handleBlank()
                        }}
                    />
                </Grid>
                <Grid item xs={4} lg={2}>
                    <SelectField
                        label="Unit"
                        id="unit"
                        value={unit || ''}
                        options={unitOptions}
                        onChange={(value) => handleChange({
                            name: 'unit',
                            value: value
                        })}
                    />
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
                    <CheckboxField
                        id="compatible-size"
                        label="Compatible size with various SD/CF-cards, SSD and hard-disk brands"
                        value={compatibleSize}
                        onChange={(checked) => handleChange({
                            name: 'compatibleSize',
                            value: checked
                        })}
                    />
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
                    <Box display="flex" justifyContent="flex-end">
                        <Stack direction="row" spacing={2} sx={{mt: 2}}>
                            <RedirectButton
                                path="/"
                                icon="ban"
                                onClick={async () => handleCancel()}
                            >
                                Cancel
                            </RedirectButton>
                            <Button
                                disabled={blankDisabled}
                                icon="plus"
                                onClick={async () => await handleBlank()}
                            >
                                Create blank image
                            </Button>
                        </Stack>
                    </Box>
                </Grid>
            </Grid>
        </Box>
    )
}