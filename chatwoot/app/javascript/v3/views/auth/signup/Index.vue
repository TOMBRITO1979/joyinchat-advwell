<script>
import { mapGetters } from 'vuex';
import { useBranding } from 'shared/composables/useBranding';
import SignupForm from './components/Signup/Form.vue';
import Testimonials from './components/Testimonials/Index.vue';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    SignupForm,
    Spinner,
    Testimonials,
  },
  setup() {
    const { replaceInstallationName } = useBranding();
    return { replaceInstallationName };
  },
  data() {
    return { isLoading: false };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    isAChatwootInstance() {
      return this.globalConfig.installationName === 'Chatwoot';
    },
  },
  beforeMount() {
    this.isLoading = this.isAChatwootInstance;
  },
  methods: {
    resizeContainers() {
      this.isLoading = false;
    },
  },
};
</script>

<template>
  <div class="w-full h-full min-h-screen bg-gradient-to-br from-purple-600 via-pink-500 to-orange-400 dark:from-purple-900 dark:via-pink-900 dark:to-orange-700 relative overflow-hidden">
    <!-- Animated background shapes -->
    <div class="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none">
      <div class="absolute top-[-10%] left-[-5%] w-96 h-96 bg-white/10 rounded-full blur-3xl animate-pulse"></div>
      <div class="absolute bottom-[-10%] right-[-5%] w-[500px] h-[500px] bg-white/10 rounded-full blur-3xl animate-pulse" style="animation-delay: 1s;"></div>
    </div>

    <div v-show="!isLoading" class="flex h-full min-h-screen items-center relative z-10">
      <div
        class="flex-1 min-h-[640px] inline-flex items-center h-full justify-center overflow-auto py-10 px-4"
      >
        <div class="w-full max-w-[480px] backdrop-blur-xl bg-white/90 dark:bg-slate-900/80 rounded-3xl shadow-2xl border border-white/20 dark:border-white/10 p-10 transform transition-all duration-500 hover:scale-[1.02] hover:shadow-purple-500/30 hover:shadow-[0_20px_60px_-15px]">
          <div class="mb-8 text-center">
            <div class="inline-block p-3 bg-gradient-to-r from-purple-500 to-pink-500 rounded-2xl mb-6 shadow-lg">
              <img
                :src="globalConfig.logo"
                :alt="globalConfig.installationName"
                class="block w-auto h-10 dark:hidden brightness-0 invert"
              />
              <img
                v-if="globalConfig.logoDark"
                :src="globalConfig.logoDark"
                :alt="globalConfig.installationName"
                class="hidden w-auto h-10 dark:block"
              />
            </div>
            <h2
              class="text-4xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 dark:from-purple-400 dark:to-pink-400 bg-clip-text text-transparent mb-3"
            >
              {{ $t('REGISTER.TRY_WOOT') }}
            </h2>
          </div>
          <SignupForm />
          <div class="mt-6 text-center text-sm text-slate-600 dark:text-slate-300">
            <span>{{ $t('REGISTER.HAVE_AN_ACCOUNT') }} </span>
            <router-link class="font-semibold text-purple-600 dark:text-purple-400 hover:text-pink-600 dark:hover:text-pink-400 transition-colors duration-300 underline decoration-2 underline-offset-2" to="/app/login">
              {{ replaceInstallationName($t('LOGIN.TITLE')) }}
            </router-link>
          </div>
        </div>
      </div>
      <Testimonials
        v-if="isAChatwootInstance"
        class="flex-1"
        @resize-containers="resizeContainers"
      />
    </div>
    <div
      v-show="isLoading"
      class="flex items-center min-h-screen justify-center w-full h-full"
    >
      <Spinner color-scheme="primary" size="" />
    </div>
  </div>
</template>
