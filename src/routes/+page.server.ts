import { fetchMarcadaDelDia, fetchDepartamentos } from '$lib/server/db';
import { getDepartamentoHost } from '$lib/utils';
import type { PageServerLoad } from './$types';


export const load: PageServerLoad = async () => {
    let defaultDate = new Date(Date.now() - 86400000).toISOString().split('T')[0];
    let hostname = getDepartamentoHost();
    try {
        /* // Fetch initial data for the default date (yesterday)
        let records = await fetchMarcadaDelDia(hostname, defaultDate); */
        let records: any[] = [];
        let departamentos: Array<string> = [];
        console.log('[PAGESERVERLOAD] fechaMarcada:', defaultDate, 'hostname:', getDepartamentoHost());
        return {
            fechaMarcada: defaultDate,
            records,
            departamentos,
            hostname,
        };
    } catch (error) {
        console.error('Error al cargar los datos:', error);
        return {
            error: 'Error al cargar los datos',
            fechaMarcada: null,
            records: [],
            departamentos: [],
            hostname: null
        };
    }
};
