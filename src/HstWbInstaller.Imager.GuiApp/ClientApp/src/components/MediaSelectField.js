import React from "react";
import {isNil} from "lodash";
import SelectField from "./SelectField";
import {formatBytes} from "../utils/Format";
import {HubConnectionBuilder} from "@microsoft/signalr";
import {Api} from "../utils/Api";

const initialState = {
    loading: true,
    medias: null
}

export default function MediaSelectField(props) {
    const {
        id,
        label,
        path,
        onChange,
    } = props
    
    const api = React.useMemo(() => new Api(), []);
    
    const [state, setState] = React.useState({...initialState})
    const [connection, setConnection] = React.useState(null);

    const {
        loading,
        medias
    } = state

    React.useEffect(() => {
        if (!isNil(connection)) {
            return
        }
        
        const newConnection = new HubConnectionBuilder()
            .withUrl('/hubs/result')
            .withAutomaticReconnect()
            .build();
        
        setConnection(newConnection)
    }, [connection, setConnection]);

    React.useEffect(() => {
        if (connection && connection.state !== "Connected") {
            connection.start()
                .then(result => {
                    connection.on('List', mediaInfos => {
                        setState({
                            medias: mediaInfos || []
                        })
                    });
                })
                .catch(e => console.log('Connection failed: ', e));
        }
    }, [connection, setState, state]);

    const handleGetMedias = React.useCallback(() => {
        async function getMedias() {
            await api.list()
            setState({
                ...state,
                loading: false
            })
        }
        getMedias()
    }, [api, setState, state])

    React.useEffect(() => {
        if (!loading) {
            return
        }
        handleGetMedias()
    }, [loading, state.session, handleGetMedias])

    const handleChange = (path) => {
        if (isNil(onChange)) {
            return
        }
        const media = (medias || []).find(media => media.path === path)
        onChange(media)
    }
    
    return (
        <SelectField
            label={label}
            id={id}
            emptyLabel="None available"
            value={path || ''}
            options={(medias || []).map((media) => {
                return {
                    title: `${media.model} (${formatBytes(media.diskSize)})`,
                    value: media.path
                }
            })}
            onChange={(value) => handleChange(value)}
        />
    )
}