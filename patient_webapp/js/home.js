export async function renderHomePage(container, sb) {
    container.innerHTML = `
        <div class="w-full max-w-4xl mx-auto p-4 md:p-6">
            <header class="flex justify-between items-center mb-6">
                <h1 class="text-3xl font-bold">My Prescriptions</h1>
                <button id="logout-btn" class="px-4 py-2 text-sm text-white bg-red-500 rounded-md hover:bg-red-600">Logout</button>
            </header>
            <div id="prescriptions-list" class="space-y-4">
                <div class="text-center p-8"><div class="loader mx-auto"></div></div>
            </div>
        </div>`;

    document.getElementById('logout-btn').addEventListener('click', () => sb.auth.signOut());
    
    try {
        const { data, error } = await sb.from('prescriptions')
            .select('*, jobs(*), medicines(*)')
            .eq('active', true)
            .order('created_at', { ascending: false });
        
        if (error) throw error;

        const listEl = document.getElementById('prescriptions-list');
        if (data.length === 0) {
            listEl.innerHTML = '<p class="text-center text-gray-500 p-8">You have no active prescriptions.</p>';
            return;
        }
        
        listEl.innerHTML = data.map(p => {
            const med = p.medicines;
            const job = p.jobs && p.jobs.length > 0 ? p.jobs[0] : null;
            return `
                <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
                    <h3 class="text-xl font-bold">${med?.name || 'N/A'}</h3>
                    <p class="text-gray-500">${med?.form || ''} - ${med?.strength || ''}</p>
                    <hr class="my-4">
                    <p><strong>Dose:</strong> ${p.dose_units} ${med?.unit || 'unit'}</p>
                    <p><strong>Schedule:</strong> ${p.schedule || 'As directed'}</p>
                    ${job ? `
                    <div class="mt-4 flex gap-4">
                        <button data-job-id="${job.id}" class="qr-btn flex-1 px-4 py-2 text-white bg-blue-600 rounded-md hover:bg-blue-700">View QR Code / PIN</button>
                        <a href="#" data-job-id="${job.id}" class="report-btn flex-1 text-center px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-100">Report Symptoms</a>
                    </div>` : ''}
                </div>`;
        }).join('');

        document.querySelectorAll('.qr-btn').forEach(btn => {
            btn.addEventListener('click', () => showQrCodeDialog(sb, btn.dataset.jobId));
        });
        document.querySelectorAll('.report-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                alert('Report Symptoms feature is not yet implemented.');
            });
        });

    } catch (error) {
        document.getElementById('prescriptions-list').innerHTML = `<p class="text-center text-red-500 p-8">Error: ${error.message}</p>`;
    }
}

// --- QR Modal Logic ---
const qrModal = document.getElementById('qrModal');
document.getElementById('closeQrModal').onclick = () => qrModal.classList.add('hidden');
window.onclick = (event) => {
    if (event.target == qrModal) qrModal.classList.add('hidden');
}

async function showQrCodeDialog(sb, jobId) {
    const qrCodeEl = document.getElementById('qrcode');
    qrCodeEl.innerHTML = '<div class="loader mx-auto"></div>';
    document.getElementById('pin-display').innerText = '...';
    qrModal.classList.remove('hidden');

    try {
        const { data, error } = await sb.functions.invoke('patient-get-ticket', { body: { job_id: jobId } });
        if (error) throw error;

        const ticketId = data.id;
        const otp = data.otp;
        const qrData = \`ticket:\${ticketId}|otp:\${otp}\`;

        qrCodeEl.innerHTML = '';
        const qrCode = new QRCodeStyling({
            width: 250, height: 250, data: qrData,
            dotsOptions: { color: '#1A3A5A', type: 'rounded' },
            backgroundOptions: { color: '#ffffff' },
        });
        qrCode.append(qrCodeEl);
        document.getElementById('pin-display').innerText = otp;

    } catch (error) {
        qrCodeEl.innerHTML = \`<p class="text-red-500">Error: Could not load ticket. ${error.message}</p>\`;
    }
}