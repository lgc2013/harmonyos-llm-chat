/**
 * 播放列表视图模型
 * 管理播放列表的状态和业务逻辑，作为 UI 与 PlaylistService 之间的桥梁
 *
 * 职责：
 * - 维护播放列表的状态数据
 * - 处理 UI 交互的业务逻辑
 * - 封装 PlaylistService 的调用
 * - 提供错误处理和加载状态管理
 */

import common from '@ohos.app.ability.common';
import { Playlist, PlaylistItem } from '../models';
import { PlaylistService, createPlaylistService } from '../services/PlaylistService';

/** 状态变化回调函数类型 */
type OnStateChangedCallback = () => void;

/**
 * 播放列表视图模型类
 * 使用观察者模式管理状态变化
 */
export class PlaylistViewModel {
  /** 播放列表服务实例 */
  private playlistService: PlaylistService | null = null;

  /** 播放列表数组 */
  private _playlists: Playlist[] = [];

  /** 当前选中的播放列表 */
  private _currentPlaylist: Playlist | null = null;

  /** 加载状态标志 */
  private _isLoading: boolean = false;

  /** 错误信息 */
  private _errorMessage: string | null = null;

  /** 状态变化回调 */
  private onStateChangedCallback: OnStateChangedCallback | null = null;

  /**
   * 获取播放列表数组
   */
  get playlists(): Playlist[] {
    return this._playlists;
  }

  /**
   * 获取当前选中的播放列表
   */
  get currentPlaylist(): Playlist | null {
    return this._currentPlaylist;
  }

  /**
   * 获取加载状态
   */
  get isLoading(): boolean {
    return this._isLoading;
  }

  /**
   * 获取错误信息
   */
  get errorMessage(): string | null {
    return this._errorMessage;
  }

  /**
   * 设置状态变化回调
   * @param callback 回调函数
   */
  setOnStateChanged(callback: OnStateChangedCallback): void {
    this.onStateChangedCallback = callback;
  }

  /**
   * 触发状态变化通知
   */
  private notifyStateChanged(): void {
    if (this.onStateChangedCallback !== null) {
      this.onStateChangedCallback();
    }
  }

  /**
   * 设置加载状态
   * @param loading 是否正在加载
   */
  private setLoading(loading: boolean): void {
    this._isLoading = loading;
    this.notifyStateChanged();
  }

  /**
   * 设置错误信息
   * @param message 错误信息
   */
  private setError(message: string | null): void {
    this._errorMessage = message;
    this.notifyStateChanged();
  }

  /**
   * 清除错误信息
   */
  clearError(): void {
    this._errorMessage = null;
    this.notifyStateChanged();
  }

  /**
   * 初始化视图模型
   * 必须在使用其他方法前调用
   * @param context 应用上下文
   */
  async initialize(context: common.UIAbilityContext): Promise<void> {
    try {
      this.setLoading(true);
      this.setError(null);

      // 创建播放列表服务实例
      this.playlistService = createPlaylistService(context);

      // 加载初始数据
      await this.loadPlaylists();

      console.info('[PlaylistViewModel] 初始化成功');
    } catch (error) {
      const err: Error = error as Error;
      const errorMsg: string = `初始化失败: ${err.message}`;
      console.error('[PlaylistViewModel]', errorMsg);
      this.setError(errorMsg);
    } finally {
      this.setLoading(false);
    }
  }

  /**
   * 加载所有播放列表
   */
  async loadPlaylists(): Promise<void> {
    if (this.playlistService === null) {
      this.setError('服务未初始化');
      return;
    }

    try {
      this.setLoading(true);
      this.setError(null);

      const loadedPlaylists: Playlist[] = await this.playlistService.getAll();
      this._playlists = loadedPlaylists;

      // 如果当前选中的播放列表存在，更新其数据
      if (this._currentPlaylist !== null) {
        const updatedCurrent: Playlist | undefined = this._playlists.find(
          (p: Playlist): boolean => p.id === this._currentPlaylist!.id
        );
        this._currentPlaylist = updatedCurrent !== undefined ? updatedCurrent : null;
      }

      this.notifyStateChanged();
      console.info('[PlaylistViewModel] 加载播放列表成功，数量:', this._playlists.length);
    } catch (error) {
      const err: Error = error as Error;
      const errorMsg: string = `加载播放列表失败: ${err.message}`;
      console.error('[PlaylistViewModel]', errorMsg);
      this.setError(errorMsg);
    } finally {
      this.setLoading(false);
    }
  }

  /**
   * 创建新播放列表
   * @param name 播放列表名称
   * @returns 新创建的播放列表
   */
  async createPlaylist(name: string): Promise<Playlist> {
    if (this.playlistService === null) {
      this.setError('服务未初始化');
      throw new Error('服务未初始化');
    }

    try {
      this.setLoading(true);
      this.setError(null);

      const newPlaylist: Playlist = await this.playlistService.create(name);
      this._playlists.push(newPlaylist);
      this.notifyStateChanged();

      console.info('[PlaylistViewModel] 创建播放列表成功:', newPlaylist.id);
      return newPlaylist;
    } catch (error) {
      const err: Error = error as Error;
      const errorMsg: string = `创建播放列表失败: ${err.message}`;
      console.error('[PlaylistViewModel]', errorMsg);
      this.setError(errorMsg);
      throw new Error(err.message);
    } finally {
      this.setLoading(false);
    }
  }

  /**
   * 删除播放列表
   * @param id 播放列表 ID
   */
  async deletePlaylist(id: string): Promise<void> {
    if (this.playlistService === null) {
      this.setError('服务未初始化');
      return;
    }

    try {
      this.setLoading(true);
      this.setError(null);

      await this.playlistService.delete(id);

      // 从本地数组中移除
      const index: number = this._playlists.findIndex((p: Playlist): boolean => p.id === id);
      if (index !== -1) {
        this._playlists.splice(index, 1);
      }

      // 如果删除的是当前选中的列表，清除选中状态
      if (this._currentPlaylist !== null && this._currentPlaylist.id === id) {
        this._currentPlaylist = null;
      }

      this.notifyStateChanged();
      console.info('[PlaylistViewModel] 删除播放列表成功:', id);
    } catch (error) {
      const err: Error = error as Error;
      const errorMsg: string = `删除播放列表失败: ${err.message}`;
      console.error('[PlaylistViewModel]', errorMsg);
      this.setError(errorMsg);
    } finally {
      this.setLoading(false);
    }
  }

  /**
   * 重命名播放列表
   * @param id 播放列表 ID
   * @param newName 新名称
   */
  async renamePlaylist(id: string, newName: string): Promise<void> {
    if (this.playlistService === null) {
      this.setError('服务未初始化');
      return;
    }

    try {
      this.setLoading(true);
      this.setError(null);

      await this.playlistService.update(id, { name: newName });

      // 更新本地数组中的数据
      const playlist: Playlist | undefined = this._playlists.find(
        (p: Playlist): boolean => p.id === id
      );
      if (playlist !== undefined) {
        const foundPlaylist: Playlist = playlist as Playlist;
        foundPlaylist.name = newName;
        foundPlaylist.updatedAt = Date.now();
      }

      // 更新当前选中列表的数据
      if (this._currentPlaylist !== null && this._currentPlaylist.id === id) {
        this._currentPlaylist.name = newName;
        this._currentPlaylist.updatedAt = Date.now();
      }

      this.notifyStateChanged();
      console.info('[PlaylistViewModel] 重命名播放列表成功:', id);
    } catch (error) {
      const err: Error = error as Error;
      const errorMsg: string = `重命名播放列表失败: ${err.message}`;
      console.error('[PlaylistViewModel]', errorMsg);
      this.setError(errorMsg);
    } finally {
      this.setLoading(false);
    }
  }

  /**
   * 添加项目到播放列表
   * @param playlistId 播放列表 ID
   * @param item 要添加的项目
   */
  async addToPlaylist(playlistId: string, item: PlaylistItem): Promise<void> {
    if (this.playlistService === null) {
      this.setError('服务未初始化');
      return;
    }

    try {
      this.setLoading(true);
      this.setError(null);

      await this.playlistService.addItem(playlistId, item);

      // 更新本地数组中的播放列表
      const playlistIndex: number = this._playlists.findIndex(
        (p: Playlist): boolean => p.id === playlistId
      );
      if (playlistIndex !== -1) {
        const playlist: Playlist = this._playlists[playlistIndex];
        playlist.items.push(item);
        playlist.totalCount = playlist.items.length;
        playlist.updatedAt = Date.now();
      }

      // 更新当前选中列表的数据
      if (this._currentPlaylist !== null && this._currentPlaylist.id === playlistId) {
        this._currentPlaylist.items.push(item);
        this._currentPlaylist.totalCount = this._currentPlaylist.items.length;
        this._currentPlaylist.updatedAt = Date.now();
      }

      this.notifyStateChanged();
      console.info('[PlaylistViewModel] 添加项目到播放列表成功:', item.id, '->', playlistId);
    } catch (error) {
      const err: Error = error as Error;
      const errorMsg: string = `添加项目失败: ${err.message}`;
      console.error('[PlaylistViewModel]', errorMsg);
      this.setError(errorMsg);
    } finally {
      this.setLoading(false);
    }
  }

  /**
   * 从播放列表移除项目
   * @param playlistId 播放列表 ID
   * @param itemId 项目 ID
   */
  async removeFromPlaylist(playlistId: string, itemId: string): Promise<void> {
    if (this.playlistService === null) {
      this.setError('服务未初始化');
      return;
    }

    try {
      this.setLoading(true);
      this.setError(null);

      await this.playlistService.removeItem(playlistId, itemId);

      // 更新本地数组中的播放列表
      const playlist: Playlist | undefined = this._playlists.find(
        (p: Playlist): boolean => p.id === playlistId
      );
      if (playlist !== undefined) {
        const foundPlaylist: Playlist = playlist as Playlist;
        const itemIndex: number = foundPlaylist.items.findIndex(
          (i: PlaylistItem): boolean => i.id === itemId
        );
        if (itemIndex !== -1) {
          foundPlaylist.items.splice(itemIndex, 1);
          foundPlaylist.totalCount = foundPlaylist.items.length;
          foundPlaylist.updatedAt = Date.now();
        }
      }

      // 更新当前选中列表的数据
      if (this._currentPlaylist !== null && this._currentPlaylist.id === playlistId) {
        const itemIndex: number = this._currentPlaylist.items.findIndex(
          (i: PlaylistItem): boolean => i.id === itemId
        );
        if (itemIndex !== -1) {
          this._currentPlaylist.items.splice(itemIndex, 1);
          this._currentPlaylist.totalCount = this._currentPlaylist.items.length;
          this._currentPlaylist.updatedAt = Date.now();
        }
      }

      this.notifyStateChanged();
      console.info('[PlaylistViewModel] 从播放列表移除项目成功:', itemId, '<-', playlistId);
    } catch (error) {
      const err: Error = error as Error;
      const errorMsg: string = `移除项目失败: ${err.message}`;
      console.error('[PlaylistViewModel]', errorMsg);
      this.setError(errorMsg);
    } finally {
      this.setLoading(false);
    }
  }

  /**
   * 根据 ID 获取播放列表
   * @param id 播放列表 ID
   * @returns 播放列表对象，不存在则返回 undefined
   */
  getPlaylistById(id: string): Playlist | undefined {
    const playlist: Playlist | undefined = this._playlists.find(
      (p: Playlist): boolean => p.id === id
    );
    return playlist;
  }

  /**
   * 选择播放列表
   * 设置当前选中的播放列表
   * @param id 播放列表 ID
   */
  selectPlaylist(id: string): void {
    const playlist: Playlist | undefined = this.getPlaylistById(id);
    if (playlist !== undefined) {
      this._currentPlaylist = playlist;
      console.info('[PlaylistViewModel] 选中播放列表:', id);
    } else {
      this._currentPlaylist = null;
      console.warn('[PlaylistViewModel] 播放列表不存在:', id);
    }
    this.notifyStateChanged();
  }

  /**
   * 取消选择当前播放列表
   */
  clearSelection(): void {
    this._currentPlaylist = null;
    this.notifyStateChanged();
  }

  /**
   * 获取播放列表数量
   * @returns 播放列表数量
   */
  getPlaylistCount(): number {
    return this._playlists.length;
  }

  /**
   * 检查是否有播放列表
   * @returns 是否有播放列表
   */
  hasPlaylists(): boolean {
    return this._playlists.length > 0;
  }

  /**
   * 检查指定播放列表是否存在
   * @param id 播放列表 ID
   * @returns 是否存在
   */
  hasPlaylist(id: string): boolean {
    return this._playlists.some((p: Playlist): boolean => p.id === id);
  }

  /**
   * 刷新当前选中的播放列表数据
   * 从服务重新加载当前列表的详细信息
   */
  async refreshCurrentPlaylist(): Promise<void> {
    if (this.playlistService === null) {
      this.setError('服务未初始化');
      return;
    }

    if (this._currentPlaylist === null) {
      return;
    }

    try {
      this.setLoading(true);
      this.setError(null);

      const refreshedPlaylist: Playlist | null = await this.playlistService.getById(
        this._currentPlaylist.id
      );

      if (refreshedPlaylist !== null) {
        this._currentPlaylist = refreshedPlaylist;

        // 同时更新数组中的数据
        const index: number = this._playlists.findIndex(
          (p: Playlist): boolean => p.id === refreshedPlaylist.id
        );
        if (index !== -1) {
          this._playlists[index] = refreshedPlaylist;
        }

        this.notifyStateChanged();
      }

      console.info('[PlaylistViewModel] 刷新当前播放列表成功');
    } catch (error) {
      const err: Error = error as Error;
      const errorMsg: string = `刷新播放列表失败: ${err.message}`;
      console.error('[PlaylistViewModel]', errorMsg);
      this.setError(errorMsg);
    } finally {
      this.setLoading(false);
    }
  }
}

/**
 * 创建播放列表视图模型实例
 * @returns PlaylistViewModel 实例
 */
export function createPlaylistViewModel(): PlaylistViewModel {
  return new PlaylistViewModel();
}
