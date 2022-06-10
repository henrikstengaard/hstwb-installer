import moment from "moment"

export const formatBytes = (bytes, decimals = 1) => {
    if (bytes === 0) return '0 Bytes';

    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

export const formatMilliseconds = (milliseconds) => {
    const duration = moment.duration(milliseconds)

    const parts = []
    const days = duration.days()
    if (days > 0) {
        parts.push(`${days} day${days > 1 ? 's' : ''}`)
    }
    
    const hours = duration.hours()
    if (hours > 0) {
        parts.push(`${hours} hour${hours > 1 ? 's' : ''}`)
    }
    
    const minutes = duration.minutes()
    if (minutes < 1) {
        const seconds = duration.seconds()
        parts.push(`${seconds} second${seconds > 1 ? 's' : ''}`)
    }
    else {
        parts.push(`${minutes} minute${minutes > 1 ? 's' : ''}`)
    }
    
    return parts.join(', ')
}