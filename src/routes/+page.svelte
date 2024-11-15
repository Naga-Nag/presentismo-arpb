<script lang="ts">
	export let data: any;
	import BtnDescargar from '$lib/components/BtnDescargar.svelte';
	import TabsDepartamento from '$lib/components/TabsDepartamento.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import RangeDatePicker from '$lib/components/RangeDatePicker.svelte';
	import MainOptions from '$lib/components/MainOptions.svelte';
	import DatePicker from '$lib/components/DatePicker.svelte';
	import { getEstado } from '$lib/utils.js';
	import { fetchMarcadas } from '$lib/mainController';
	import {
		globalStore,
		toggleEntreFechas,
		updateFechaMarcada,
		setloadingData
	} from '$lib/globalStore';
	import { onMount } from 'svelte';
	import LoadingIcon from '$lib/components/LoadingIcon.svelte';

	// Variables para búsqueda y departamentos
	let registros = data.records;
	let searchText: string = '';
	let departamentos: string[] = String(data.departamentos).split(',') ?? [];
	let selectedDepartamento: string = data.hostname;
	let showEntreFechas: boolean;
	let hostname = data.hostname;
	let fechaMarcada = '';
	let loading: boolean;

	globalStore.subscribe((value) => {
		selectedDepartamento = value.selectedDepartamento;
		showEntreFechas = value.showEntreFechas;
		fechaMarcada = value.fechaMarcada;
		loading = value.loading;
	});

	// Computamos los datos filtrados en función del departamento seleccionado, el texto de búsqueda y la ordenación
	$: filteredData = registros
		.filter((persona: { Nombre: string; Departamento: string; MR: number }) => {
			// Si el hostname es PEAP, filtramos por departamento, si no, ignoramos el departamento
			if (data.hostname === 'PEAP') {
				if (selectedDepartamento === 'ARPB') {
					return (
						persona.Nombre.toLowerCase().includes(searchText.toLowerCase()) ||
						persona.MR.toString().includes(searchText)
					);
				} else {
					return (
						persona.Departamento === selectedDepartamento &&
						(persona.Nombre.toLowerCase().includes(searchText.toLowerCase()) ||
							persona.MR.toString().includes(searchText))
					);
				}
			} else {
				// Si no es PEAP, solo filtramos por el texto de búsqueda
				return (
					(persona.Departamento === selectedDepartamento &&
						persona.Nombre.toLowerCase().includes(searchText.toLowerCase())) ||
					persona.MR.toString().includes(searchText)
				);
			}
		}) //Agregamos estado a cada marcada
		.map((persona: { Entrada: string; Salida: string }) => ({
			...persona,
			Estado: getEstado(persona)
		}));

	let filteredAusentesDepartamento = filterAusentesDepartamento(selectedDepartamento);

	function filterAusentes() {
		return data.records.filter(
			(persona: { Entrada: any; Salida: any }) => !persona.Entrada || !persona.Salida
		);
	}

	function filterAusentesDepartamento(dep: String) {
		let datos = data.records.filter(
			(persona: { Departamento: string; Entrada: any; Salida: any }) =>
				persona.Departamento === selectedDepartamento && (!persona.Entrada || !persona.Salida)
		);
		return datos;
	}

	async function rangoFechalistener(fechaInicial: string, fechaFinal: string) {
		setloadingData(true);
		let url = `/api/fetchEntreFechas/`;
		let payload = { departamento: hostname, fechaInicial, fechaFinal };
		try {
			console.log('Fetching data... MarcadaEntreFechas:', fechaInicial, fechaFinal);
			const response = await fetch(url, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				body: JSON.stringify(payload)
			});
			if (response.ok) {
				registros = await response.json();
			} else {
				console.error('Error fetching data:', await response.json());
			}
		} catch (error) {
			console.error('Fetch error:', error);
		}
		setloadingData(false);
	}

	async function fechaListener(fechaMarcada: string) {
		registros = []; // Clear previous records

		try {
			fetchMarcadas(hostname, fechaMarcada, (batch) => {
				registros = [...registros, ...batch]; // Update registros incrementally
			});
		} catch (error) {
			console.error('Error fetching data:', error);
			error = error.message;
		} finally {
		}
	}

	function toggleEntreFechasResetData() {
		toggleEntreFechas();
		filteredData = [];
		registros = [];
	}

	onMount(async () => {
		let defaultDate = new Date(Date.now() - 86400000).toISOString().split('T')[0];
		updateFechaMarcada(defaultDate);
		fechaListener(defaultDate);
	});
</script>

<body>
	<main class="main shadow:8|8|3|blue">
		<div class="d:flex flex:row justify-content:space-between">
			<h1 class="text:center bg:white r:10 p:10 w:fit-content shadow:4|4|3|gray-70">
				Presentismo - {data.hostname}
			</h1>
			<a href="/aut" class="font-size:9">👻</a>
		</div>

		<!-- Tabs de departamentos -->
		{#if data.hostname === 'PEAP'}
			<TabsDepartamento {departamentos} bind:selectedDepartamento />
		{/if}

		<LoadingIcon></LoadingIcon>

		<!-- Campo de búsqueda -->
		<input
			type="text"
			placeholder="Buscar por nombre o MR"
			bind:value={searchText}
			class="b:1|solid|#ccc mb:10 p:8 w:99% r:4"
		/>

		<!-- DatePicker y Botones para exportar datos -->
		<div class="d:flex mb:10">
			<span> </span>
			<MainOptions {showEntreFechas} on:showEntreFechas={toggleEntreFechasResetData} />
			<span></span>

			{#if showEntreFechas}
				<RangeDatePicker
					on:rangoFechaDefinido={(e) =>
						rangoFechalistener(e.detail.fechaInicial, e.detail.fechaFinal)}
				></RangeDatePicker>
			{:else}
				<DatePicker on:fechaDefinida={(e) => fechaListener(e.detail.fecha)}></DatePicker>
			{/if}

			<BtnDescargar
				data={filteredData}
				placeholder="Descargar Vista Actual"
				filename="marcadas VA - {selectedDepartamento} {data.fechaMarcada}"
			/>
			<BtnDescargar
				data={filteredAusentesDepartamento}
				placeholder="Descargar Ausentes del Departamento"
				filename="marcadas AD - {selectedDepartamento} {data.fechaMarcada}"
			/>
			{#if data.hostname === 'PEAP'}
				<BtnDescargar
					data={filterAusentes()}
					placeholder="Descargar Todos los Ausentes"
					filename="marcadas TD {data.fechaMarcada}"
				/>
			{/if}
		</div>

		<!-- Tabla de datos filtrados -->
		{#if registros.length > 0 && !loading}
			<DataTable registros={filteredData} />
			<!-- Cuenta de registros -->
			<div class="d:flex flex:col">
				<p class="font-size:18 bg:white r:10 p:10 w:fit-content">
					Total Ausentes: {filterAusentesDepartamento(selectedDepartamento).length}
				</p>
			</div>
		{/if}
	</main>
</body>

<style>
</style>
