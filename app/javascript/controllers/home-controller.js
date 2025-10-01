import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    comment_view() {
        document.getElementById('comment-box').style.display = 'block';
    }

    comment_close() {
        document.getElementById('comment-box').style.display = 'none';
    }
}