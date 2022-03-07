export class Api {
    async list() {
        const response = await fetch('api/list', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            }
        });
        if (!response.ok) {
            console.error('Failed to get list')
        }
    }
}
