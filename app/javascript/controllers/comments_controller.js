//@ts-nocheck
import { Controller } from "@hotwired/stimulus";

/** @import { Context } from "@hotwired/stimulus"  */

const EVENTS = {
    SHOW: "comment:show",
    HIDE: "comment:hide",
};

// Connects to data-controller="comments"
/** @extends {Controller<HTMLDivElement>} */
export default class extends Controller {
    static targets = ["content", "title"];

    boundShow = this.show.bind(this);
    boundHide = this.hide.bind(this);
    currentStoreId = null;

    connect() {
        console.log("Comments controller connected");

        // 初期状態では非表示
        this.hide();

        window.addEventListener(EVENTS.SHOW, this.boundShow);
        window.addEventListener(EVENTS.HIDE, this.boundHide);
    }

    disconnect() {
        window.removeEventListener(EVENTS.SHOW, this.boundShow);
        window.removeEventListener(EVENTS.HIDE, this.boundHide);
    }

    /**
     * @param {CustomEvent} event
     */
    show(event) {
        const { storeId, storeName } = event.detail || {};

        if (storeId) {
            this.currentStoreId = storeId;
            this.loadReviews(storeId, storeName);
        }

        this.element.classList.remove("hidden");
    }

    hide() {
        this.element.classList.add("hidden");
    }

    /**
     * 店舗のレビューを読み込む
     * @param {number} storeId
     * @param {string} storeName
     */
    async loadReviews(storeId, storeName) {
        // タイトルを更新
        if (this.hasTitleTarget) {
            this.titleTarget.textContent = `${storeName || '店舗'}のレビュー`;
        }

        // コンテンツエリアを取得
        const contentElement = this.hasContentTarget
            ? this.contentTarget
            : this.element.querySelector('.comments__content');

        if (!contentElement) {
            console.error("Content element not found");
            return;
        }

        // ローディング表示
        contentElement.innerHTML = '<p class="comments__loading">読み込み中...</p>';

        try {
            // レビューデータを取得
            const response = await fetch(`/reviews.json?reviewee_id=${storeId}`);

            if (!response.ok) {
                throw new Error('レビューの取得に失敗しました');
            }

            const reviews = await response.json();

            // レビューを表示
            this.displayReviews(reviews, contentElement);
        } catch (error) {
            console.error('Error loading reviews:', error);
            contentElement.innerHTML = '<p class="comments__error">レビューの読み込みに失敗しました</p>';
        }
    }

    /**
     * レビューを表示
     * @param {Array} reviews
     * @param {HTMLElement} contentElement
     */
    displayReviews(reviews, contentElement) {
        if (!reviews || reviews.length === 0) {
            contentElement.innerHTML = '<p class="comments__empty">まだレビューはありません</p>';
            return;
        }

        const reviewsHTML = reviews.map(review => `
            <div class="comments__item">
                <div class="comments__item-header">
                    <div class="comments__rating">
                        ${this.renderStars(review.rating)}
                    </div>
                    <div class="comments__date">
                        ${this.formatDate(review.created_at)}
                    </div>
                </div>
                ${review.comment ? `
                    <p class="comments__item-text">${this.escapeHtml(review.comment)}</p>
                ` : ''}
            </div>
        `).join('');

        contentElement.innerHTML = reviewsHTML;
    }

    /**
     * 星評価を表示
     * @param {number} rating
     * @returns {string}
     */
    renderStars(rating) {
        const fullStars = Math.floor(rating || 0);
        const stars = [];

        for (let i = 0; i < 5; i++) {
            if (i < fullStars) {
                stars.push('<span class="star star--filled">★</span>');
            } else {
                stars.push('<span class="star star--empty">☆</span>');
            }
        }

        return stars.join('');
    }

    /**
     * 日付をフォーマット
     * @param {string} dateString
     * @returns {string}
     */
    formatDate(dateString) {
        const date = new Date(dateString);
        const year = date.getFullYear();
        const month = date.getMonth() + 1;
        const day = date.getDate();
        return `${year}年${month}月${day}日`;
    }

    /**
     * HTMLエスケープ
     * @param {string} text
     * @returns {string}
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

/**
 * コメント表示をトリガー
 * @param {number} storeId
 * @param {string} storeName
 */
export function triggerShowComments(storeId, storeName) {
    const event = new CustomEvent(EVENTS.SHOW, {
        detail: { storeId, storeName }
    });
    window.dispatchEvent(event);
}

/**
 * コメント非表示をトリガー
 */
export function triggerHideComments() {
    const event = new Event(EVENTS.HIDE);
    window.dispatchEvent(event);
}
