import React from 'react'
import Box from "@mui/material/Box";
import Title from "../components/Title";
export default function Partition() {
    return (
        <Box>
            <Title
                text="Partition"
                description="Edit partition table for physical disk or image file."
            />
            <p>
                Not implemented yet.
            </p>
            <p>
                Ideas for partition functionality ordered by priority:
                <ol>
                    <li>Initialize disk with new Rigid Disk Block (RDB).</li>
                    <li>Create, edit, delete partitions.</li>
                    <li>Create, edit, delete file systems.</li>
                    <li>Ability to create Hybrid disks with both RDB and MBR, so Amiga has access to both Amiga file systems and a FAT32 partition for file transfer.</li>
                    <li>Format FFS and PFS3 without using an Amiga emulator.</li>
                    <li>Import and export partitions as single .hdf files.</li>
                </ol>
            </p>
        </Box>
    )
}