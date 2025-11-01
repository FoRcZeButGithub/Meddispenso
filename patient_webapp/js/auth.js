export function renderAuthForm(container, sb, isLogin = true) {
    container.innerHTML = `
        <div class="w-full max-w-md p-8 space-y-6 bg-white rounded-xl shadow-lg mx-auto">
            <h2 class="text-3xl font-bold text-center">${isLogin ? 'Welcome Back!' : 'Create Account'}</h2>
            <p class="text-center text-gray-500">${isLogin ? 'Sign in to continue' : 'Sign up to get started'}</p>
            <form id="auth-form" class="mt-8 space-y-6">
                ${!isLogin ? `
                    <input id="first_name" type="text" required class="w-full px-4 py-2 border border-gray-300 rounded-md" placeholder="First Name">
                    <input id="last_name" type="text" required class="w-full px-4 py-2 border border-gray-300 rounded-md" placeholder="Last Name">
                ` : ''}
                <input id="email" type="email" required class="w-full px-4 py-2 border border-gray-300 rounded-md" placeholder="Email Address">
                <input id="password" type="password" required class="w-full px-4 py-2 border border-gray-300 rounded-md" placeholder="Password">
                <button type="submit" class="w-full px-4 py-2 text-white bg-blue-600 rounded-md hover:bg-blue-700">${isLogin ? 'Sign In' : 'Create Account'}</button>
            </form>
            <p class="text-center">
                <a href="#" id="toggle-auth-mode" class="text-blue-600 hover:underline">
                    ${isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In"}
                </a>
            </p>
        </div>`;
    
    document.getElementById('toggle-auth-mode').addEventListener('click', (e) => {
        e.preventDefault();
        renderAuthForm(container, sb, !isLogin);
    });

    document.getElementById('auth-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        
        if (isLogin) {
            const { error } = await sb.auth.signInWithPassword({ email, password });
            if (error) alert(error.message);
        } else {
            const firstName = document.getElementById('first_name').value;
            const lastName = document.getElementById('last_name').value;
            const { data, error } = await sb.auth.signUp({ email, password });
            if (error) {
                alert(error.message);
            } else if (data.user) {
                await sb.from('patients').insert([{ user_id: data.user.id, first_name: firstName, last_name: lastName }]);
                alert('Sign up successful! Please sign in.');
                renderAuthForm(container, sb, true);
            }
        }
    });
}