<script lang="ts">
    import { afterUpdate, getContext, onDestroy } from 'svelte';

    import css from './Image.module.css';

    import type { LayoutParams } from '../../types/layoutParams';
    import type { DivImageData, TintMode } from '../../types/image';
    import type { DivBase, TemplateContext } from '../../../typings/common';
    import type { AlignmentHorizontal, AlignmentVertical } from '../../types/alignment';
    import Outer from '../utilities/Outer.svelte';
    import { makeStyle } from '../../utils/makeStyle';
    import { genClassName } from '../../utils/genClassName';
    import { ROOT_CTX, RootCtxValue } from '../../context/root';
    import { wrapError } from '../../utils/wrapError';
    import { imageSize } from '../../utils/background';
    import { correctImagePosition } from '../../utils/correctImagePosition';
    import { isPositiveNumber } from '../../utils/isPositiveNumber';
    import { correctColor } from '../../utils/correctColor';
    import { correctCSSInterpolator } from '../../utils/correctCSSInterpolator';
    import { correctNonNegativeNumber } from '../../utils/correctNonNegativeNumber';
    import { correctTintMode } from '../../utils/correctTintMode';
    import { getCssFilter } from '../../utils/filters';
    import { prepareBase64 } from '../../utils/prepareBase64';

    export let json: Partial<DivImageData> = {};
    export let templateContext: TemplateContext;
    export let origJson: DivBase | undefined = undefined;
    export let layoutParams: LayoutParams | undefined = undefined;

    const FALLBACK_IMAGE = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
    const EMPTY_IMAGE = 'empty://';
    // const DEFAULT_PLACEHOLDER_COLOR = correctColor('#14000000');
    const DEFAULT_PLACEHOLDER_COLOR = 'rgba(0,0,0,0.08)';

    const STATE_LOADING = 0;
    const STATE_LOADED = 1;
    const STATE_ERROR = 2;

    const rootCtx = getContext<RootCtxValue>(ROOT_CTX);

    let img: HTMLImageElement;
    let state = STATE_LOADING;
    let isEmpty = false;
    let isLottie = false;
    let placeholderColor = DEFAULT_PLACEHOLDER_COLOR;

    $: jsonImageUrl = rootCtx.getDerivedFromVars(json.image_url);
    $: jsonGifUrl = rootCtx.getDerivedFromVars(json.gif_url);

    let imageUrl: string | undefined;
    $: {
        let img = json.type === 'gif' ? $jsonGifUrl : $jsonImageUrl;
        isEmpty = img === EMPTY_IMAGE;
        if (isEmpty) {
            img = FALLBACK_IMAGE;
        }
        imageUrl = img;
    }

    function updateImageUrl(_url: string | undefined): void {
        state = STATE_LOADING;
    }
    $: updateImageUrl(imageUrl);

    let hasError = false;
    $: {
        if (!imageUrl) {
            hasError = true;
            rootCtx.logError(wrapError(new Error(`Missing "${json.type === 'gif' ? 'gif_url' : 'image_url'}" for "${json.type}"`)));
        } else {
            hasError = false;
        }
    }

    $: jsonWidth = rootCtx.getDerivedFromVars(json.width);
    $: isWidthContent = $jsonWidth?.type === 'wrap_content';

    $: jsonHeight = rootCtx.getDerivedFromVars(json.height);
    $: isHeightContent = $jsonHeight?.type === 'wrap_content';

    $: jsonPreview = rootCtx.getDerivedFromVars(json.preview);
    let backgroundImage = '';
    $: {
        const preview = $jsonPreview;

        if ((state === STATE_LOADING || state === STATE_ERROR || isEmpty) && preview) {
            backgroundImage = `url("${prepareBase64(preview)}")`;
        } else {
            backgroundImage = '';
        }
    }

    $: jsonPlaceholderColor = rootCtx.getDerivedFromVars(json.placeholder_color);
    $: if (state === STATE_LOADING || state === STATE_ERROR || isEmpty) {
        placeholderColor = correctColor($jsonPlaceholderColor, 1, placeholderColor);
    } else {
        placeholderColor = '';
    }

    $: jsonScale = rootCtx.getDerivedFromVars(json.scale);
    // Exactly "none", "scale-down" would not match android
    let scale = 'none';
    $: {
        scale = imageSize($jsonScale) || scale;
    }

    $: jsonPosition = rootCtx.getDerivedFromVars({
        content_alignment_horizontal: json.content_alignment_horizontal,
        content_alignment_vertical: json.content_alignment_vertical
    });
    let position = '50% 50%';
    function updatePosition(pos: {
        content_alignment_horizontal?: AlignmentHorizontal;
        content_alignment_vertical?: AlignmentVertical;
    }): void {
        position = correctImagePosition(pos, position);
    }
    $: updatePosition($jsonPosition);

    $: jsonA11y = rootCtx.getDerivedFromVars(json.accessibility);
    $: alt = $jsonA11y?.description || '';

    $: jsonAspect = rootCtx.getDerivedFromVars(json.aspect);
    let aspectPaddingBottom = '0';
    $: {
        const newRatio = $jsonAspect?.ratio;
        if (newRatio && isPositiveNumber(newRatio)) {
            aspectPaddingBottom = (100 / Number(newRatio)).toFixed(2);
        } else {
            aspectPaddingBottom = '0';
        }
    }

    $: jsonTintColor = rootCtx.getDerivedFromVars(json.tint_color);
    let tintColor: string | undefined = undefined;
    $: jsonTintMode = rootCtx.getDerivedFromVars(json.tint_mode);
    let tintMode: TintMode = 'source_in';
    let svgFilterId = '';
    $: {
        const val = $jsonTintColor;
        const newTintColor = val ? correctColor(val) : undefined;
        const newTintMode = correctTintMode($jsonTintMode, tintMode);
        if (newTintColor !== tintColor || newTintMode !== tintMode) {
            rootCtx.removeSvgFilter(tintColor, tintMode);
            svgFilterId = newTintColor ? rootCtx.addSvgFilter(newTintColor, newTintMode) : '';
            tintColor = newTintColor;
            tintMode = newTintMode;
        }
    }

    $: jsonAppearanceAnimation = rootCtx.getDerivedFromVars(json.appearance_animation);
    let animationInterpolator = '';
    let animationFadeStart = 0;
    let animationDelay = 0;
    let animationDuration = 0;

    $: if ($jsonAppearanceAnimation && $jsonAppearanceAnimation.type === 'fade') {
        const animation = $jsonAppearanceAnimation;

        animationInterpolator = correctCSSInterpolator(animation.interpolator, 'ease_in_out').replace(/_/g, '-');
        animationDuration = correctNonNegativeNumber(animation.duration, 300);
        animationDelay = correctNonNegativeNumber(animation.start_delay, 0);
        animationFadeStart = correctNonNegativeNumber(animation.alpha, 0);
    }

    $: jsonFilters = rootCtx.getDerivedFromVars(json.filters);
    let filter = '';
    let filterClipPath = '';
    $: {
        let newFilter = '';
        let newClipPath = '';
        if (Array.isArray($jsonFilters) && $jsonFilters.length) {
            newFilter = getCssFilter($jsonFilters, rootCtx.logError);
        }
        if (newFilter) {
            newClipPath = 'polygon(0% 0%, 0% 100%, 100% 100%, 100% 0%)';
        }
        filter = newFilter;
        filterClipPath = newClipPath;
    }

    $: mods = {
        aspect: aspectPaddingBottom !== '0',
        'is-width-content': isWidthContent,
        'is-height-content': isHeightContent,
        loaded: state === STATE_LOADED,
        'before-appearance': Boolean(animationInterpolator) && state === STATE_LOADING
    };

    $: style = {
        display: isLottie ? 'none' : undefined,
        // Image preview shows, if loading of original image is failed
        'background-image': backgroundImage,
        'background-color': backgroundImage ? undefined : placeholderColor,
        'background-size': scale,
        'clip-path': filterClipPath || undefined,
        'object-fit': scale,
        'object-position': position,
        filter: [
            state === STATE_LOADED && svgFilterId ? `url(#${svgFilterId})` : '',
            filter
        ].filter(Boolean).join(' '),
        '--divkit-appearance-interpolator': animationInterpolator || undefined,
        '--divkit-appearance-fade-start': animationInterpolator ? animationFadeStart : undefined,
        '--divkit-appearance-delay': animationInterpolator ? `${animationDelay}ms` : undefined,
        '--divkit-appearance-duration': animationInterpolator ? `${animationDuration}ms` : undefined
    };

    function onLoad(): void {
        if (state === STATE_LOADING) {
            state = STATE_LOADED;
        }
    }

    function onError(): void {
        if (state === STATE_LOADING) {
            state = STATE_ERROR;
        }
    }

    afterUpdate(() => {
        if (!img) {
            return;
        }
        const node = img.closest('.' + css.image);
        if (node && node.getAttribute('data-lottie')) {
            isLottie = true;
        }
    });

    onDestroy(() => {
        rootCtx.removeSvgFilter(tintColor, tintMode);
    });

    // Recreate image on svg filter change for the Safari
</script>

{#if !hasError}
    <Outer
        cls={genClassName('image', css, mods)}
        {json}
        {origJson}
        {templateContext}
        {layoutParams}
        customDescription={true}
    >
        {#key svgFilterId}
            {#if mods.aspect}
                <span class={css['image__aspect-wrapper']} style:padding-bottom="{aspectPaddingBottom}%">
                    <img
                        bind:this={img}
                        class={css.image__image}
                        src={state === STATE_ERROR ? FALLBACK_IMAGE : imageUrl}
                        loading="lazy"
                        decoding="async"
                        style={makeStyle(style)}
                        {alt}
                        aria-hidden={alt ? null : 'true'}
                        on:load={onLoad}
                        on:error={onError}
                    >
                </span>
            {:else}
                <img
                    bind:this={img}
                    class={css.image__image}
                    src={state === STATE_ERROR ? FALLBACK_IMAGE : imageUrl}
                    loading="lazy"
                    decoding="async"
                    style={makeStyle(style)}
                    {alt}
                    aria-hidden={alt ? null : 'true'}
                    on:load={onLoad}
                    on:error={onError}
                >
            {/if}
        {/key}
    </Outer>
{/if}
