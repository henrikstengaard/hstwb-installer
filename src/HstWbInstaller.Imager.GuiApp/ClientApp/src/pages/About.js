import React from 'react'
import Box from "@mui/material/Box";
import Title from "../components/Title";
import Link from '@mui/material/Link'
import {ElectronIpc} from "../utils/ElectronIpc"
import {AppStateContext} from "../components/AppStateContext";
import Typography from "@mui/material/Typography";
import {HSTWB_INSTALLER_VERSION} from '../Constants'

const payPalDonateUrl = 'https://www.paypal.com/donate/?business=7DZM5VEGWWNP8&no_recurring=0&item_name=Thanks+for+your+incredible+effort+creating+HstWB+Installer+and+Imager+in+your+spare+time.+I+want+to+support+future+development.&currency_code=EUR'
const gitHubIssuesUrl = 'https://github.com/henrikstengaard/hstwb-installer/issues'

export default function About() {
    const electronIpc = new ElectronIpc()
    const appState = React.useContext(AppStateContext)

    const openUrl = async (event, url) => {
        event.preventDefault()
        if (!appState || !appState.isElectronActive)
        {
            console.error('Open url is only available with Electron')
            return
        }
        await electronIpc.openExternal({
            url
        })
    }
    
    return (
        <Box>
            <Title
                text="About"
            />
            <Typography sx={{ mt: 2 }}>
                HstWB Imager v{HSTWB_INSTALLER_VERSION}.
            </Typography>
            <Typography sx={{ mt: 2 }}>
                HstWB Imager is an imaging tool to read and write raw disk images to and from physical drives with support for Amiga rigid disk block (RDSK, partition table used by Amiga computers).
                This is useful for creating images on modern computers and write them to physical drives such as hard disks, SSD, CF- and MicroSD-cards or creating images of physical drives for backup or tweaking with Amiga emulators much faster than real Amiga hardware.
            </Typography>
            <Typography sx={{ mt: 2 }}>
                HstWB Imager is created and maintained by Henrik Nørfjand Stengaard in his spare time. To support future development and appreciate your use of HstWB Imager, please make a donation via <Link href="#" onClick={async (event) => openUrl(event, payPalDonateUrl)}>PayPal donate</Link>.
            </Typography>
            <Typography sx={{ mt: 2 }}>
                Please report issues by creating a new issue at <Link href="#" onClick={async (event) => openUrl(event, gitHubIssuesUrl)}>Github issues</Link>.
            </Typography>
        </Box>
    )
}